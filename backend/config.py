"""
GateKeeper – Configurazione
============================
Tutte le variabili d'ambiente vengono lette qui tramite Pydantic BaseSettings.

Come usarlo:
  1. Crea un file `.env` nella cartella `backend/` (NON committarlo, è in .gitignore)
  2. Imposta le variabili come mostrato nel file `.env.example`
  3. `from config import settings` per accedere ai valori ovunque

Se una variabile non è nel .env, viene usato il valore di default definito qui.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Settings dell'applicazione.

    Attributi:
        database_url: URL connessione SQLAlchemy.
            Default: SQLite locale (file gatekeeper.db).
            Per PostgreSQL: postgresql://user:pass@host/dbname
        secret_key: Chiave segreta per firmare i JWT.
            DEVE essere cambiata in produzione con una stringa random lunga.
        algorithm: Algoritmo usato per i JWT (default HS256).
        access_token_expire_minutes: Durata del token in minuti (default 60).
        allowed_origins: Lista origini permesse per CORS.
    """

    # Database
    database_url: str = "sqlite:///./gatekeeper.db"

    # JWT
    secret_key: str = "CAMBIA_QUESTA_CHIAVE_IN_PRODUZIONE_usa_openssl_rand_hex_32"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # CORS – in sviluppo accetta tutto, in prod metti il dominio Cloudflare
    allowed_origins: list[str] = ["*"]

    # TODO: aggiungi qui le variabili per il reader RFID UHF (porta seriale, baud rate)
    # rfid_port: str = "/dev/ttyUSB0"
    # rfid_baud_rate: int = 115200

    # TODO: aggiungi variabili per BLE scanner
    # ble_scan_interval_seconds: int = 5

    model_config = SettingsConfigDict(
        env_file=".env",       # legge il file .env se esiste
        env_file_encoding="utf-8",
        case_sensitive=False,  # SECRET_KEY e secret_key sono equivalenti
    )


# Istanza singleton importata dagli altri moduli
settings = Settings()
