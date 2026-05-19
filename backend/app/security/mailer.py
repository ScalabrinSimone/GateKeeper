"""Mailer del progetto GateKeeper.

Supporta invio reale via SMTP (es. Gmail con App Password) e fallback
locale su file `outbox.log` + stampa terminale.

Configurazione via variabili d'ambiente (o file `.env` nella root backend):
- GK_SMTP_HOST      (es. "smtp.gmail.com")
- GK_SMTP_PORT      (es. "587", default 587)
- GK_SMTP_USER      (es. "gatekeeper.casa@gmail.com")
- GK_SMTP_PASSWORD  (App Password di 16 caratteri, NON la password Google)
- GK_SMTP_FROM      (opzionale, default = GK_SMTP_USER)

=== SETUP GMAIL (App Password) ===
1. Crea un account Google dedicato (es. gatekeeper.casa@gmail.com).
2. Attiva la verifica in 2 passaggi su quell'account:
   https://myaccount.google.com/signinoptions/two-step-verification
3. Genera un'App Password:
   https://myaccount.google.com/apppasswords
   - Scegli "Posta" come app e "Altro" come dispositivo (scrivi "GateKeeper").
   - Google ti darà una password di 16 caratteri (es. "abcd efgh ijkl mnop").
4. Imposta le variabili d'ambiente nel terminale o in un file `.env`:
   GK_SMTP_HOST=smtp.gmail.com
   GK_SMTP_PORT=587
   GK_SMTP_USER=gatekeeper.casa@gmail.com
   GK_SMTP_PASSWORD=abcdefghijklmnop
   GK_SMTP_FROM=gatekeeper.casa@gmail.com

Il backend legge queste variabili all'avvio. Se mancano, le mail vengono
solo stampate nel terminale e salvate in `outbox.log`.
"""

from __future__ import annotations

import os
import smtplib
from datetime import datetime, timezone
from email.message import EmailMessage
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path


OUTBOX_PATH = Path(__file__).resolve().parents[2] / "outbox.log"

#Carica variabili da file .env nella root backend (se esiste).
#Cerca in più posizioni per robustezza (dipende da dove viene avviato il backend).
_POSSIBLE_ENV_PATHS = [
    Path(__file__).resolve().parents[2] / ".env",          # backend/.env (da mailer.py)
    Path.cwd() / ".env",                                    # CWD/.env
    Path.cwd() / "backend" / ".env",                        # CWD/backend/.env (se avviato dalla root repo)
]

_env_loaded = False
for _env_path in _POSSIBLE_ENV_PATHS:
    if _env_path.is_file():
        try:
            with _env_path.open(encoding="utf-8") as _f:
                for _line in _f:
                    _line = _line.strip()
                    if not _line or _line.startswith("#"):
                        continue
                    if "=" in _line:
                        _key, _val = _line.split("=", 1)
                        _key = _key.strip()
                        _val = _val.strip().strip('"').strip("'")
                        if _key:
                            os.environ[_key] = _val
            _env_loaded = True
            print(f"[MAILER] OK - File .env caricato da: {_env_path}")
            break
        except Exception as _exc:
            print(f"[MAILER] ERRORE lettura .env ({_env_path}): {_exc}")

if not _env_loaded:
    print("[MAILER] WARN - Nessun file .env trovato. SMTP non configurato (solo terminale + outbox.log).")


def _log_outbox(to: str, subject: str, body: str) -> None:
    """Salva una mail in file locale (modalità fallback)."""
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


def _print_terminal(to: str, subject: str, body: str) -> None:
    """Stampa sempre la mail nel terminale per debug/sviluppo."""
    print(f"\n{'='*60}")
    print(f"[MAILER] TO:   {to}")
    print(f"[MAILER] SUBJ: {subject}")
    print(f"[MAILER] BODY:\n{body}")
    print(f"{'='*60}\n")


def _ensure_env_loaded() -> None:
    """Ricarica le variabili d'ambiente da .env se non ancora caricate.

    Chiamato prima di ogni invio mail per coprire il caso in cui il backend
    venga avviato direttamente da uvicorn (senza run_all.py) o da una directory
    diversa da quella del progetto.
    """
    if os.getenv("GK_SMTP_HOST"):
        return  # gia' caricato
    for _env_path in _POSSIBLE_ENV_PATHS:
        if _env_path.is_file():
            try:
                with _env_path.open(encoding="utf-8") as _f:
                    for _line in _f:
                        _line = _line.strip()
                        if not _line or _line.startswith("#"):
                            continue
                        if "=" in _line:
                            _k, _v = _line.split("=", 1)
                            _k = _k.strip()
                            _v = _v.strip().strip('"').strip("'")
                            if _k:
                                os.environ[_k] = _v
                print(f"[MAILER] ENV ricaricato da: {_env_path}")
                break
            except Exception:
                pass


def send_mail(to: str, subject: str, body: str) -> bool:
    """Invia una mail via SMTP. Stampa SEMPRE nel terminale + outbox.log.

    Se SMTP è configurato, invia anche la mail reale. Se l'invio fallisce,
    il contenuto resta comunque visibile nel terminale e nel file outbox.log.
    """
    #Assicura che le variabili d'ambiente siano caricate (lazy reload).
    _ensure_env_loaded()

    #Stampa sempre nel terminale (utile in sviluppo e per vedere i codici).
    _print_terminal(to, subject, body)
    #Salva sempre in outbox.log come backup.
    _log_outbox(to, subject, body)

    host = os.getenv("GK_SMTP_HOST")
    if not host:
        print("[MAILER] SMTP non configurato: mail solo in terminale + outbox.log")
        return True

    try:
        port = int(os.getenv("GK_SMTP_PORT", "587"))
        user = os.getenv("GK_SMTP_USER", "")
        pw = os.getenv("GK_SMTP_PASSWORD", "")
        sender = os.getenv("GK_SMTP_FROM", user or "gatekeeper@localhost")

        #Costruisce il messaggio con header leggibili.
        msg = MIMEMultipart("alternative")
        msg["From"] = f"GateKeeper <{sender}>"
        msg["To"] = to
        msg["Subject"] = subject

        #Versione testo semplice.
        msg.attach(MIMEText(body, "plain", "utf-8"))

        #Versione HTML minimale (migliora la leggibilità nei client email).
        html_body = (
            "<div style='font-family:sans-serif;max-width:480px;margin:auto;"
            "padding:24px;border:1px solid #eee;border-radius:12px'>"
            f"<h2 style='color:#00767A;margin:0 0 16px'>🛡️ GateKeeper</h2>"
            f"<p style='white-space:pre-wrap;line-height:1.6'>{body}</p>"
            "<hr style='border:none;border-top:1px solid #eee;margin:20px 0'>"
            "<p style='font-size:11px;color:#999'>Questa email è stata inviata "
            "automaticamente dal sistema GateKeeper.</p>"
            "</div>"
        )
        msg.attach(MIMEText(html_body, "html", "utf-8"))

        with smtplib.SMTP(host, port, timeout=15) as smtp:
            smtp.ehlo()
            smtp.starttls()
            smtp.ehlo()
            if user:
                smtp.login(user, pw)
            smtp.sendmail(sender, [to], msg.as_string())

        print(f"[MAILER] OK - Email inviata con successo a {to}")
        return True
    except Exception as exc:
        print(f"[MAILER] ERRORE - Invio SMTP fallito: {exc}")
        print(f"[MAILER]   (la mail resta visibile sopra nel terminale e in outbox.log)")
        return False
