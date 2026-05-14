"""Mailer minimale.

In ambiente locale (es. test su PC senza SMTP) le mail vengono scritte in un
file `outbox.log` accanto al backend, così l'utente può leggerle.
In produzione (Raspberry Pi) si può configurare un vero SMTP via variabili
d'ambiente:
- GK_SMTP_HOST
- GK_SMTP_PORT
- GK_SMTP_USER
- GK_SMTP_PASSWORD
- GK_SMTP_FROM
"""

from __future__ import annotations

import os
import smtplib
from datetime import datetime, timezone
from email.message import EmailMessage
from pathlib import Path


OUTBOX_PATH = Path(__file__).resolve().parents[2] / "outbox.log"


def _log_outbox(to: str, subject: str, body: str) -> None:
    """Salva una mail in file locale (modalità mock)."""
    try:
        OUTBOX_PATH.parent.mkdir(parents=True, exist_ok=True)
        with OUTBOX_PATH.open("a", encoding="utf-8") as fp:
            fp.write("=" * 60 + "\n")
            fp.write(f"DATE: {datetime.now(timezone.utc).isoformat()}\n")
            fp.write(f"TO:   {to}\n")
            fp.write(f"SUBJ: {subject}\n")
            fp.write("\n")
            fp.write(body.rstrip() + "\n\n")
    except Exception as exc:
        print(f"[MAILER] Impossibile scrivere outbox: {exc}")


def send_mail(to: str, subject: str, body: str) -> bool:
    """Invia una mail. Se SMTP non configurato, scrive su outbox.log."""
    host = os.getenv("GK_SMTP_HOST")
    if not host:
        _log_outbox(to, subject, body)
        return True

    try:
        port = int(os.getenv("GK_SMTP_PORT", "587"))
        user = os.getenv("GK_SMTP_USER", "")
        pw = os.getenv("GK_SMTP_PASSWORD", "")
        sender = os.getenv("GK_SMTP_FROM", user or "gatekeeper@localhost")

        msg = EmailMessage()
        msg["From"] = sender
        msg["To"] = to
        msg["Subject"] = subject
        msg.set_content(body)

        with smtplib.SMTP(host, port, timeout=10) as smtp:
            smtp.starttls()
            if user:
                smtp.login(user, pw)
            smtp.send_message(msg)
        return True
    except Exception as exc:
        print(f"[MAILER] Invio fallito ({exc}), salvo in outbox.log")
        _log_outbox(to, subject, body)
        return False
