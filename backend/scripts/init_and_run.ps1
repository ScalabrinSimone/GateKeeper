# Script PowerShell per creare l'ambiente virtuale, installare dipendenze
# e avviare il server FastAPI in sviluppo.
python -m venv .venv
. .venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m app.db.init_db
uvicorn app.api.endpoint:app --reload --host 0.0.0.0 --port 8000
