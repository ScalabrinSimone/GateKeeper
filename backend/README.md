# Mini progetto Raspberry Pi — FastAPI + SQLite (test)

Setup rapido:

1. Creare virtualenv e installare dipendenze:

```bash
python -m venv .venv
.venv\Scripts\activate    # PowerShell/Windows
pip install -r requirements.txt
```

2. Inizializzare il DB:

```bash
python -m app.db.init_db
```

3. Avviare il server:

```bash
uvicorn app.api.main:app --reload --host 0.0.0.0 --port 8000
```
Sostituire con:

```bash
uvicorn app.api.endpoint:app --reload --host 0.0.0.0 --port 8000
```

Test rapidi con `scripts/test_requests.sh` o `scripts/test_requests.ps1`.
