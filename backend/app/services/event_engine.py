"""Event Engine: logica di correlazione BLE + RFID per generare eventi di passaggio.

Questo modulo è il cuore del sistema GateKeeper. Funziona così:

1. Gli utenti registrano il MAC address BLE del proprio telefono (via app).
2. Quando il lettore RFID rileva un tag associato a un device:
   - Controlla quali telefoni BLE sono vicini alla porta.
   - Se un telefono registrato è presente, associa l'evento all'utente.
   - Crea un evento `passage_in` o `passage_out` con i device rilevati.
   - Aggiorna lo stato dei device (inside/outside).
   - Invia notifiche se necessario (oggetti essenziali dimenticati, ecc.).
3. Se un tag RFID passa SENZA un telefono BLE associato nelle vicinanze:
   - Crea un evento `alert` (possibile furto o uscita non autorizzata).

Il modulo espone un loop che gira in un thread daemon e coordina i dati
provenienti dal BLE scanner e dal RFID reader.
"""

from __future__ import annotations

import json
import threading
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Set

from app.db import models
from app.security.mailer import send_mail


# =========================================================
# CONFIGURAZIONE
# =========================================================

#Finestra temporale (secondi) entro cui un dispositivo BLE è considerato
#"vicino alla porta" dopo l'ultima rilevazione.
BLE_PROXIMITY_WINDOW = 30.0

#Intervallo di polling del loop principale (secondi).
ENGINE_LOOP_INTERVAL = 2.0

#Cooldown (secondi) tra due eventi per lo stesso tag RFID (evita duplicati
#se il tag resta nel campo del lettore per qualche secondo).
RFID_EVENT_COOLDOWN = 15.0

# =========================================================
# STATO GLOBALE BLE (alimentato dal blescanner)
# =========================================================

#Mappa: ble_address -> {last_seen: float, name: str, is_phone: bool}
_ble_nearby: Dict[str, Dict[str, Any]] = {}
_ble_lock = threading.Lock()


def ble_device_seen(address: str, name: str = "", is_phone: bool = False) -> None:
    """Chiamata dal BLE scanner ogni volta che rileva un dispositivo.

    Aggiorna il timestamp di ultima rilevazione per quell'indirizzo.
    """
    with _ble_lock:
        _ble_nearby[address] = {
            "last_seen": time.time(),
            "name": name,
            "is_phone": is_phone,
        }


def get_nearby_ble_phones() -> List[Dict[str, Any]]:
    """Restituisce i telefoni BLE rilevati entro la finestra di prossimità."""
    now = time.time()
    result = []
    with _ble_lock:
        for addr, info in _ble_nearby.items():
            if now - info["last_seen"] <= BLE_PROXIMITY_WINDOW:
                if info.get("is_phone", False):
                    result.append({"address": addr, **info})
    return result


def get_all_nearby_ble() -> List[Dict[str, Any]]:
    """Restituisce TUTTI i dispositivi BLE rilevati entro la finestra."""
    now = time.time()
    result = []
    with _ble_lock:
        for addr, info in _ble_nearby.items():
            if now - info["last_seen"] <= BLE_PROXIMITY_WINDOW:
                result.append({"address": addr, **info})
    return result


# =========================================================
# REGISTRAZIONE BLE <-> UTENTE
# =========================================================

#Mappa persistente: ble_address -> user_id.
#Caricata dal database all'avvio e aggiornata quando un utente registra
#il proprio dispositivo BLE.
_ble_user_map: Dict[str, int] = {}
_ble_user_lock = threading.Lock()


def _load_ble_user_map() -> None:
    """Carica le associazioni BLE->utente dal database."""
    global _ble_user_map
    with _ble_user_lock:
        _ble_user_map = {}
        try:
            from app.db.storage import DB_LOCK, load_db
            with DB_LOCK:
                db = load_db()
                for user in db.get("users", []):
                    ble_addr = user.get("ble_address")
                    if ble_addr and isinstance(ble_addr, str) and ble_addr.strip():
                        _ble_user_map[ble_addr.strip().upper()] = user["id"]
        except Exception as exc:
            print(f"[EVENT-ENGINE] Errore caricamento mappa BLE: {exc}")


def register_ble_address(user_id: int, ble_address: str) -> bool:
    """Registra un indirizzo BLE per un utente.

    Salva nel database e aggiorna la mappa in memoria.
    """
    ble_address = (ble_address or "").strip().upper()
    if not ble_address:
        return False
    try:
        from app.db.storage import DB_LOCK, load_db, save_db, find_by_id
        with DB_LOCK:
            db = load_db()
            user = find_by_id(db["users"], user_id)
            if user is None:
                return False
            #Rimuovi l'indirizzo da altri utenti (un BLE = un utente).
            for u in db["users"]:
                if u.get("ble_address", "").strip().upper() == ble_address:
                    u["ble_address"] = None
            user["ble_address"] = ble_address
            save_db(db)
        with _ble_user_lock:
            #Rimuovi vecchie associazioni per questo utente.
            _ble_user_map.update(
                {k: v for k, v in _ble_user_map.items() if v != user_id}
            )
            _ble_user_map[ble_address] = user_id
        return True
    except Exception as exc:
        print(f"[EVENT-ENGINE] Errore registrazione BLE: {exc}")
        return False


def get_ble_address_for_user(user_id: int) -> Optional[str]:
    """Restituisce l'indirizzo BLE registrato per un utente."""
    with _ble_user_lock:
        for addr, uid in _ble_user_map.items():
            if uid == user_id:
                return addr
    return None


def find_user_by_ble(ble_address: str) -> Optional[int]:
    """Trova l'utente associato a un indirizzo BLE."""
    ble_address = (ble_address or "").strip().upper()
    with _ble_user_lock:
        return _ble_user_map.get(ble_address)


# =========================================================
# RFID EVENT TRACKING (evita duplicati)
# =========================================================

#Mappa: rfid_tag -> ultimo timestamp di evento generato.
_rfid_last_event: Dict[str, float] = {}
_rfid_event_lock = threading.Lock()


def _can_generate_event(tag: str) -> bool:
    """Controlla se è passato abbastanza tempo dall'ultimo evento per questo tag."""
    now = time.time()
    with _rfid_event_lock:
        last = _rfid_last_event.get(tag, 0.0)
        if now - last < RFID_EVENT_COOLDOWN:
            return False
        _rfid_last_event[tag] = now
        return True


# =========================================================
# LOGICA PRINCIPALE: PROCESSO UN TAG RFID
# =========================================================


def process_rfid_tag(tag: str) -> Optional[Dict[str, Any]]:
    """Processa un tag RFID rilevato dal lettore.

    Questa è la funzione principale dell'event engine:
    1. Cerca il device associato al tag.
    2. Determina la direzione (in/out) in base allo stato corrente.
    3. Cerca telefoni BLE vicini per associare un utente.
    4. Crea l'evento e aggiorna gli stati.
    5. Invia notifiche se necessario.

    Restituisce il dict dell'evento creato, o None se non è stato generato.
    """
    tag = (tag or "").strip()
    if not tag:
        return None

    #Cooldown: evita eventi duplicati per lo stesso tag.
    if not _can_generate_event(tag):
        return None

    #1. Cerca il device.
    device = models.get_device_by_rfid_tag(tag)
    if device is None:
        #Tag sconosciuto: lo memorizziamo per la registrazione (già fatto dal callback).
        return None

    #2. Determina la direzione.
    current_status = device.get("current_status", "inside")
    if current_status == "inside":
        direction = "out"
        new_status = "outside"
        event_type = "passage_out"
    else:
        direction = "in"
        new_status = "inside"
        event_type = "passage_in"

    #3. Cerca telefoni BLE vicini e associa un utente.
    nearby_phones = get_nearby_ble_phones()
    associated_user_id: Optional[int] = None
    detected_users_list: List[Dict[str, Any]] = []

    for phone in nearby_phones:
        addr = phone.get("address", "").upper()
        uid = find_user_by_ble(addr)
        if uid is not None:
            associated_user_id = uid
            user_info = models.get_user_by_id(uid)
            if user_info:
                detected_users_list.append({
                    "user_id": uid,
                    "username": user_info.get("username"),
                    "ble_address": addr,
                })

    #4. Crea l'evento.
    detected_objects_list = [{
        "device_id": device["id"],
        "name": device["name"],
        "rfid_tag": tag,
        "category": device.get("category"),
        "is_essential": device.get("is_essential", False),
    }]

    try:
        event_id = models.create_event(
            user_id=associated_user_id,
            event_type=event_type,
            direction=direction,
            detected_objects=detected_objects_list,
            detected_users=detected_users_list,
        )
    except Exception as exc:
        print(f"[EVENT-ENGINE] Errore creazione evento: {exc}")
        return None

    #5. Aggiorna lo stato del device.
    try:
        models.update_device(device["id"], current_status=new_status)
    except Exception as exc:
        print(f"[EVENT-ENGINE] Errore aggiornamento stato device: {exc}")

    #6. Crea un log di passaggio.
    if associated_user_id is not None:
        try:
            action = "USCITO" if direction == "out" else "ENTRATO"
            models.create_log(associated_user_id, device["id"], action)
        except Exception as exc:
            print(f"[EVENT-ENGINE] Errore creazione log: {exc}")

        #Aggiorna la posizione dell'utente.
        try:
            new_location = "outside" if direction == "out" else "inside"
            models.update_user(associated_user_id, current_location=new_location)
        except Exception:
            pass

    #7. Controlla se servono notifiche.
    _check_and_notify(device, direction, associated_user_id, nearby_phones)

    event = models.get_event_by_id(event_id)
    _log_event(event_type, direction, device, associated_user_id)
    return event


def _log_event(
    event_type: str,
    direction: str,
    device: Dict[str, Any],
    user_id: Optional[int],
) -> None:
    """Stampa un log leggibile dell'evento nel terminale."""
    arrow = "→ FUORI" if direction == "out" else "← DENTRO"
    user_str = f"utente #{user_id}" if user_id else "NESSUN UTENTE"
    print(
        f"\n[EVENT-ENGINE] ⚡ {arrow} | "
        f"device=\"{device.get('name')}\" (tag={device.get('rfid_tag')}) | "
        f"{user_str} | tipo={event_type}"
    )


# =========================================================
# NOTIFICHE
# =========================================================


def _check_and_notify(
    device: Dict[str, Any],
    direction: str,
    user_id: Optional[int],
    nearby_phones: List[Dict[str, Any]],
) -> None:
    """Controlla le condizioni di notifica e invia alert se necessario."""

    device_name = device.get("name", "Oggetto")
    is_essential = device.get("is_essential", False)

    #Caso 1: Oggetto esce SENZA telefono associato nelle vicinanze.
    #Possibile furto o uscita non autorizzata.
    if direction == "out" and user_id is None:
        _send_alert_to_all(
            title="⚠️ Oggetto in uscita senza utente",
            body=(
                f"L'oggetto \"{device_name}\" è uscito di casa ma nessun "
                f"telefono registrato è stato rilevato nelle vicinanze.\n"
                f"Potrebbe trattarsi di un'uscita non autorizzata."
            ),
            event_type="alert",
            device=device,
        )
        #Crea anche un evento alert nel database.
        try:
            models.create_event(
                user_id=None,
                event_type="alert",
                direction="out",
                detected_objects=[{
                    "device_id": device["id"],
                    "name": device_name,
                    "rfid_tag": device.get("rfid_tag"),
                    "reason": "no_user_nearby",
                }],
                detected_users=[],
            )
        except Exception:
            pass
        return

    #Caso 2: Oggetto essenziale esce (con utente). Notifica informativa.
    if direction == "out" and is_essential and user_id is not None:
        user = models.get_user_by_id(user_id)
        username = user.get("username", "Utente") if user else "Utente"
        _send_notification_to_user(
            user_id=user_id,
            title=f"📦 {device_name} è uscito con te",
            body=f"L'oggetto essenziale \"{device_name}\" è stato rilevato in uscita.",
        )

    #Caso 3: Oggetto rientra. Notifica informativa all'utente.
    if direction == "in" and user_id is not None:
        _send_notification_to_user(
            user_id=user_id,
            title=f"🏠 {device_name} è rientrato",
            body=f"\"{device_name}\" è stato rilevato in ingresso.",
        )


def _send_alert_to_all(
    title: str,
    body: str,
    event_type: str = "alert",
    device: Optional[Dict[str, Any]] = None,
) -> None:
    """Invia una notifica a TUTTI gli utenti attivi (email + terminale)."""
    print(f"\n[NOTIFY] 🚨 ALERT A TUTTI: {title}")
    print(f"[NOTIFY]    {body}\n")

    try:
        users = models.list_users(is_active=True)
        for user in users:
            email = user.get("email", "")
            if email and not email.endswith("@local.invalid"):
                try:
                    send_mail(
                        to=email,
                        subject=f"GateKeeper Alert · {title}",
                        body=body,
                    )
                except Exception as exc:
                    print(f"[NOTIFY] Errore invio email a {email}: {exc}")
    except Exception as exc:
        print(f"[NOTIFY] Errore recupero utenti: {exc}")


def _send_notification_to_user(
    user_id: int,
    title: str,
    body: str,
) -> None:
    """Invia una notifica a un singolo utente (email + terminale)."""
    print(f"[NOTIFY] 📬 Per utente #{user_id}: {title}")

    try:
        user = models.get_user_by_id(user_id)
        if user:
            email = user.get("email", "")
            if email and not email.endswith("@local.invalid"):
                try:
                    send_mail(
                        to=email,
                        subject=f"GateKeeper · {title}",
                        body=body,
                    )
                except Exception as exc:
                    print(f"[NOTIFY] Errore invio email a {email}: {exc}")
    except Exception as exc:
        print(f"[NOTIFY] Errore recupero utente #{user_id}: {exc}")


# =========================================================
# INTEGRAZIONE CON IL CALLBACK RFID ESISTENTE
# =========================================================

_engine_started = False
_engine_lock = threading.Lock()


def start_engine() -> None:
    """Inizializza l'event engine. Chiamato all'avvio del server."""
    global _engine_started
    with _engine_lock:
        if _engine_started:
            return
        _engine_started = True
    _load_ble_user_map()
    print("[EVENT-ENGINE] ✓ Engine avviato. Mappa BLE caricata.")
    with _ble_user_lock:
        if _ble_user_map:
            print(f"[EVENT-ENGINE]   {len(_ble_user_map)} associazioni BLE->utente caricate.")
        else:
            print("[EVENT-ENGINE]   Nessuna associazione BLE->utente trovata.")


def rfid_event_callback(tag: str) -> None:
    """Callback da usare nel lettore RFID al posto di quella originale.

    Questa funzione:
    1. Memorizza il tag sconosciuto (per la UX di registrazione).
    2. Processa il tag tramite l'event engine (genera eventi reali).
    """
    #Memorizza sempre il tag nel buffer "unknown" (per la registrazione).
    try:
        models.remember_unknown_tag(tag)
    except Exception as exc:
        print(f"[EVENT-ENGINE] Errore remember_unknown_tag: {exc}")

    #Processa il tag per generare eventi.
    process_rfid_tag(tag)
