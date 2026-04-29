#!/usr/bin/env bash
# Script semplice per inizializzare l'ambiente e avviare il server
set -e
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m app.db.init_db
uvicorn app.api.endpoint:app --reload --host 0.0.0.0 --port 8000
