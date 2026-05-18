# 📥 Installazione

## Prerequisiti

- **Python 3.11+**
- **Git**
- (Opzionale) **Flutter SDK** per lo sviluppo dell'app

## Backend

### 1. Clona il repository

```bash
git clone https://github.com/ScalabrinSimone/GateKeeper.git
cd GateKeeper
```

### 2. Crea un ambiente virtuale

```bash
cd backend
python -m venv .venv
```

**Windows:**
```powershell
.venv\Scripts\activate
```

**Linux/macOS:**
```bash
source .venv/bin/activate
```

### 3. Installa le dipendenze

```bash
pip install -r requirements.txt
```

### 4. Avvia il backend

```bash
python run_all.py
```

Il server sarà disponibile su `http://localhost:8000`.

## App Flutter

### 1. Posizionati nella cartella app

```bash
cd app
```

### 2. Installa le dipendenze Flutter

```bash
flutter pub get
```

### 3. Avvia l'app

```bash
flutter run
```

## Hardware (Raspberry Pi)

### Connessione Lettore RFID

1. Collega il lettore RFID UHF via USB al Raspberry Pi
2. Il sistema rileverà automaticamente la porta seriale (CH340/CH910)
3. Verifica la connessione con:

```bash
python -m app.rfid.rfidreader
```

### BLE

Il BLE integrato del Raspberry Pi viene utilizzato automaticamente dallo scanner.

## Verifica dell'Installazione

1. Avvia il backend (`python run_all.py`)
2. Apri `http://localhost:8000` — dovresti vedere il messaggio di health check
3. Crea un utente di test:

```bash
curl -X POST http://localhost:8000/users \
  -H "Content-Type: application/json" \
  -d '{"username": "test", "password": "test123"}'
```
