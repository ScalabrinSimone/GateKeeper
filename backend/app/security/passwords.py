"""Wrapper sottile su werkzeug per hashing e verifica password."""

from __future__ import annotations

from werkzeug.security import check_password_hash, generate_password_hash


def hash_password(plain: str) -> str:
    """Crea l'hash di una password in chiaro."""
    return generate_password_hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    """Verifica una password contro l'hash salvato."""
    if not plain or not hashed:
        return False
    try:
        return check_password_hash(hashed, plain)
    except Exception:
        return False
