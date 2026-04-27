# 💡 L'idea

## Cos'è GateKeeper?

GateKeeper è un sistema IoT domestico intelligente progettato per tenere traccia
di **chi entra ed esce di casa** e **quali oggetti vengono portati fuori**,
rilevando automaticamente eventuali situazioni di rischio come dimenticanze,
bambini non supervisionati o movimenti sospetti.

---

## Il problema che risolve

Quante volte sei uscito di casa dimenticando le chiavi, l'ombrello o il telefono?
GateKeeper nasce per rispondere a questa esigenza in modo **automatico e non invasivo**,
senza richiedere azioni manuali da parte dell'utente.

---

## Come funziona (in breve)

Il sistema si basa su **eventi**, non su tracking continuo:

- la porta è il punto di controllo centrale
- ogni volta che un oggetto o una persona transita, GateKeeper lo rileva
- associa l'utente agli oggetti e prende decisioni contestuali
- invia notifiche smart solo quando necessario

---

## Concetto chiave

> GateKeeper **non ti sorveglia**.
> Interviene solo quando qualcosa di rilevante accade alla porta.

---

## Esempi pratici

| Situazione | Notifica |
|---|---|
| Esci senza ombrello con pioggia prevista | ☔ "Hai dimenticato l'ombrello!" |
| Un bambino esce senza supervisione | 👶 "Bambino uscito senza adulti" |
| Oggetto sensibile dimenticato | 🔒 "Ti sei scordato di prendere {oggetto}" |

---

## In una frase

> GateKeeper è un sistema IoT domestico basato su Raspberry Pi che combina
> RFID e BLE per tracciare oggetti e utenti, con accesso remoto sicuro
> e gestione multi-utente tramite app Flet.