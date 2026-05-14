"""Gestione di token di sessione semplici (HMAC firmati).

Non è un JWT completo: è una forma minimale ma sicura per LAN/uso domestico.
Struttura: base64url(payload).base64url(hmac_sha256(payload, secret)).

Payload JSON con:
- sub: user_id
- role: ruolo utente
- iat: epoch issued at
- exp: epoch expires at
- jti: id univoco del token (per revoche)
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import secrets
import time
from pathlib import Path
from typing import Any, Dict, Optional


SECRET_PATH = Path(__file__).resolve().parent / ".jwt_secret"


def _b64(data: bytes) -> str:
    """Encoding base64url senza padding."""
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _b64d(text: str) -> bytes:
    """Decoding base64url tollerante al padding."""
    padding = "=" * (-len(text) % 4)
    return base64.urlsafe_b64decode(text + padding)


def _load_or_create_secret() -> bytes:
    """Carica il secret persistito, o ne crea uno nuovo (solo prima volta)."""
    if SECRET_PATH.exists():
        try:
            return SECRET_PATH.read_bytes()
        except Exception:
            pass
    raw = secrets.token_bytes(48)
    try:
        SECRET_PATH.parent.mkdir(parents=True, exist_ok=True)
        SECRET_PATH.write_bytes(raw)
        try:
            os.chmod(SECRET_PATH, 0o600)
        except Exception:
            pass
    except Exception:
        pass
    return raw


_SECRET = _load_or_create_secret()


def reset_secret() -> None:
    """Forza il rinnovo del secret (es. dopo un factory reset)."""
    global _SECRET
    try:
        if SECRET_PATH.exists():
            SECRET_PATH.unlink()
    except Exception:
        pass
    _SECRET = _load_or_create_secret()


def encode_token(payload: Dict[str, Any], *, ttl_seconds: int = 60 * 60 * 24 * 30) -> str:
    """Crea un token firmato. TTL di default: 30 giorni."""
    now = int(time.time())
    full_payload = dict(payload)
    full_payload.setdefault("iat", now)
    full_payload.setdefault("exp", now + ttl_seconds)
    full_payload.setdefault("jti", secrets.token_hex(8))

    raw_payload = json.dumps(full_payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    body = _b64(raw_payload)
    signature = hmac.new(_SECRET, body.encode("ascii"), hashlib.sha256).digest()
    return f"{body}.{_b64(signature)}"


def decode_token(token: str) -> Optional[Dict[str, Any]]:
    """Decodifica e verifica un token. Ritorna None se non valido/scaduto."""
    if not token or "." not in token:
        return None
    try:
        body, sig = token.split(".", 1)
        expected_sig = hmac.new(_SECRET, body.encode("ascii"), hashlib.sha256).digest()
        if not hmac.compare_digest(_b64d(sig), expected_sig):
            return None
        payload = json.loads(_b64d(body).decode("utf-8"))
        if not isinstance(payload, dict):
            return None
        exp = int(payload.get("exp", 0))
        if exp and exp < int(time.time()):
            return None
        return payload
    except Exception:
        return None
