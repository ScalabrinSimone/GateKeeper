# 🚀 Primo Avvio

## 1. Avvia il Backend

```bash
cd backend
python run_all.py
```

Al primo avvio, il database JSON viene creato automaticamente con le collezioni vuote.

Per inizializzare o resettare il database:
```bash
python run_all.py --reset-db
```

Oppure usa lo script dedicato:
```bash
python -m app.db.init_db --force
```

## 2. Verifica lo Stato del Server

Apri il browser su `http://localhost:8000` — dovresti ricevere una risposta di health check.

## 3. Crea il Primo Utente

```bash
curl -X POST http://localhost:8000/users \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123", "role": "admin"}'
```

## 4. Registra un Dispositivo

```bash
curl -X POST http://localhost:8000/devices \
  -H "Content-Type: application/json" \
  -d '{"name": "Ombrello", "category": "accessory", "is_essential": false}'
```

## 5. Associa Utente e Dispositivo

```bash
# Sostituisci user_id e device_id con i valori reali
curl -X POST http://localhost:8000/user-devices \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "device_id": 1}'
```

## 6. Avvia l'App Flutter

```bash
cd app
flutter run
```

L'app si connetterà al backend. Nella schermata di login, inserisci le credenziali create al punto 3.

> Nota: l'autenticazione non è ancora implementata, quindi l'app utilizza dati mock.

## 7. Testa il Sistema

### Simula un'Entrata/Uscita

```bash
curl -X POST http://localhost:8000/logs \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "device_id": 1, "action": "USCITO"}'
```

### Verifica i Log

```bash
curl http://localhost:8000/logs
```

## Risoluzione Problemi

### Il backend non si avvia
- Verifica che Python 3.11+ sia installato: `python --version`
- Verifica che tutte le dipendenze siano installate: `pip list`
- Controlla che la porta 8000 non sia già in uso

### Il lettore RFID non viene rilevato
- Verifica che il lettore sia collegato via USB
- Controlla il driver seriale (CH340/CH910)
- Prova a specificare la porta manualmente

### L'app Flutter non si connette
- Verifica che il backend sia in esecuzione
- Controlla l'URL dell'API nelle impostazioni dell'app
- Se usi un emulatore Android, usa `10.0.2.2` invece di `localhost`
