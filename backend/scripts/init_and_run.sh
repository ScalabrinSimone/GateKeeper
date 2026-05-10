#!/usr/bin/env bash
# Script per creare l'ambiente virtuale, installare le dipendenze e avviare tutto.
set -e

python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python run_all.py
