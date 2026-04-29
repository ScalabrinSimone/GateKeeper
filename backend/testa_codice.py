#!/usr/bin/env python3
"""Script console per interagire con il DB `test.db`.
Menu minimale per aggiungere e leggere: utenti, dispositivi, associazioni e log.
"""
from typing import Any, Dict, List
from app.db import models


def print_rows(rows: List[Dict[str, Any]]):
    if not rows:
        print("(vuoto)")
        return
    # stampa intestazione
    keys = list(rows[0].keys())
    widths = [max(len(str(r[k])) for r in rows + [{k: k}]) for k in keys]
    header = " | ".join(k.ljust(w) for k, w in zip(keys, widths))
    sep = "-+-".join("-" * w for w in widths)
    print(header)
    print(sep)
    for r in rows:
        print(" | ".join(str(r[k]).ljust(w) for k, w in zip(keys, widths)))


def create_user():
    username = input("Username: ").strip()
    if not username:
        print("Username non valido")
        return
    password = input("Password: ").strip()
    try:
        user_id = models.create_user(username, password)
        print(f"Utente creato con id {user_id}")
    except ValueError as e:
        print(f"Errore: {e}")


def list_users():
    # models non fornisce una list_users; usiamo query diretta
    from app.db import models as m
    with m._connect() as conn:
        cur = conn.cursor()
        cur.execute("SELECT id, username, created_at FROM users ORDER BY id")
        rows = [dict(r) for r in cur.fetchall()]
        print_rows(rows)


def create_device():
    name = input("Nome dispositivo: ").strip()
    if not name:
        print("Nome non valido")
        return
    device_id = models.create_device(name)
    print(f"Dispositivo creato con id {device_id}")


def list_devices():
    rows = models.list_devices()
    print_rows(rows)


def associate():
    try:
        user_id = int(input("User id: ").strip())
        device_id = int(input("Device id: ").strip())
    except ValueError:
        print("Id non valido")
        return
    try:
        assoc_id = models.associate_user_device(user_id, device_id)
        print(f"Associazione creata id {assoc_id}")
    except Exception as e:
        print(f"Errore: {e}")


def add_log():
    try:
        user_id = int(input("User id: ").strip())
        device_id = int(input("Device id: ").strip())
    except ValueError:
        print("Id non valido")
        return
    action = input("Azione (ENTRATO/USCITO): ").strip().upper()
    if action not in ("ENTRATO", "USCITO"):
        print("Azione non valida")
        return
    try:
        log_id = models.create_log(user_id, device_id, action)
        print(f"Log creato id {log_id}")
    except Exception as e:
        print(f"Errore: {e}")


def list_logs():
    try:
        u = input("Filtra per user_id (vuoto = nessuno): ").strip()
        d = input("Filtra per device_id (vuoto = nessuno): ").strip()
        user_id = int(u) if u else None
        device_id = int(d) if d else None
    except ValueError:
        print("Id non valido")
        return
    rows = models.list_logs(user_id=user_id, device_id=device_id)
    print_rows(rows)


def menu():
    options = [
        ("1", "Crea utente", create_user),
        ("2", "Lista utenti", list_users),
        ("3", "Aggiungi dispositivo", create_device),
        ("4", "Lista dispositivi", list_devices),
        ("5", "Associa utente-dispositivo", associate),
        ("6", "Aggiungi log (ENTRATO/USCITO)", add_log),
        ("7", "Lista logs", list_logs),
        ("0", "Esci", None),
    ]
    while True:
        print("\n--- MENU DB ---")
        for k, desc, _ in options:
            print(f"{k}) {desc}")
        choice = input("Seleziona opzione: ").strip()
        for k, _, fn in options:
            if k == choice:
                if k == "0":
                    print("Arrivederci")
                    return
                fn()
                break
        else:
            print("Opzione non valida")


if __name__ == "__main__":
    try:
        menu()
    except KeyboardInterrupt:
        print("\nInterrotto dall'utente")
