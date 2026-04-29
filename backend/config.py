"""
config.py — Configurazione centralizzata dell'applicazione.

Usa pydantic-settings per leggere le variabili dal file .env
(o dall'ambiente di sistema) e renderle disponibili come oggetto
tipizzato in tutta l'app.

Utilizzo:
    from config import settings
    print(settings.SECRET_KEY)
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Contenitore per tutte le variabili di configurazione.

    Ogni campo corrisponde a una variabile nel file .env.
    pydantic-settings le legge automaticamente (case-insensitive).

    Attributi:
        APP_NAME: Nome dell'applicazione (usato nell'intestazione OpenAPI).
        APP_VERSION: Versione semver.
        DEBUG: Se True, abilita log verbosi e reload automatico.
        DATABASE_URL: Stringa di connessione SQLAlchemy.
        SECRET_KEY: Chiave HMAC per firmare i JWT. Tienila segreta!
        ALGORITHM: Algoritmo JWT (default HS256).
        ACCESS_TOKEN_EXPIRE_MINUTES: Durata token in minuti.
        ALLOWED_ORIGINS: Lista origini CORS permesse.
    """

    APP_NAME: str = "GateKeeper"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = False

    # --- Database ---
    DATABASE_URL: str = "sqlite+aiosqlite:///./gatekeeper.db"

    # --- JWT ---
    SECRET_KEY: str = "insecure-default-change-me"  # TODO: sovrascrivere in .env!
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # --- CORS ---
    # La stringa viene splitta su "," in main.py
    ALLOWED_ORIGINS: str = "http://localhost"

    # Dice a pydantic-settings di cercare il file ".env" nella directory corrente
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


# Istanza singleton: importa questo oggetto ovunque ti serva la config
settings = Settings()
