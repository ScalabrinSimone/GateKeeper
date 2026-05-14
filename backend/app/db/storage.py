"""Strato di persistenza NoSQL basato su file JSON.

Il progetto originario usava SQLite. Qui la persistenza è stata
convertita in un database documentale locale, semplice e autonomo,
senza dipendenze da un server esterno.

La struttura del file è:

{
  "meta": {
    "version": 1,
    "next_ids": {
      "users": 1,
      "devices": 1,
      "user_devices": 1,
      "logs": 1,
      "events": 1
    }
  },
  "users": [],
  "devices": [],
  "user_devices": [],
  "logs": [],
  "events": []
}
"""

from __future__ import annotations

import json
import os
import shutil
import threading
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable

DB_PATH = Path(__file__).resolve().with_name("nosql_db.json")
TABLES = (
    "users",
    "devices",
    "user_devices",
    "logs",
    "events",
    "invites",
    "password_resets",
)

DB_LOCK = threading.RLock()


def _empty_db() -> Dict[str, Any]:
    """Crea una struttura DB vuota con contatori ID iniziali."""
    return {
        "meta": {
            "version": 2,
            "next_ids": {table: 1 for table in TABLES},
            # Stato dell'hub: singolo record (non è una tabella).
            "hub": {
                "paired": False,
                "house_name": None,
                "admin_user_id": None,
                "paired_at": None,
                "factory_code": None,
            },
        },
        **{table: [] for table in TABLES},
    }


def _now_iso() -> str:
    """Timestamp standard ISO 8601 in UTC."""
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _backup_path(path: Path) -> Path:
    """Percorso del file di backup per un DB incompatibile/corrotto."""
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    return path.with_name(f"{path.stem}_backup_{stamp}{path.suffix}")


def _atomic_write(path: Path, data: Dict[str, Any]) -> None:
    """Scrittura atomica su disco per evitare file parziali."""
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = path.with_suffix(path.suffix + ".tmp")
    tmp_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    os.replace(tmp_path, path)


def _normalize_db(raw: Any) -> Dict[str, Any]:
    """Rende la struttura valida e completa.

    Se il file contiene campi mancanti, vengono aggiunti.
    Se un record non ha un id valido, viene corretto.
    """
    if not isinstance(raw, dict):
        raise ValueError("database root must be a JSON object")

    normalized = _empty_db()

    meta = raw.get("meta", {})
    if isinstance(meta, dict):
        version = meta.get("version", 1)
        try:
            normalized["meta"]["version"] = int(version)
        except Exception:
            normalized["meta"]["version"] = 1
        next_ids = meta.get("next_ids", {})
        if isinstance(next_ids, dict):
            for table in TABLES:
                try:
                    value = int(next_ids.get(table, 1))
                except Exception:
                    value = 1
                normalized["meta"]["next_ids"][table] = max(1, value)
        # Hub singleton: viene letto se presente, altrimenti resta il default.
        hub = meta.get("hub", {})
        if isinstance(hub, dict):
            current = normalized["meta"]["hub"]
            current["paired"] = bool(hub.get("paired", current["paired"]))
            current["house_name"] = hub.get("house_name", current["house_name"])
            current["admin_user_id"] = hub.get("admin_user_id", current["admin_user_id"])
            current["paired_at"] = hub.get("paired_at", current["paired_at"])
            current["factory_code"] = hub.get("factory_code", current["factory_code"])

    for table in TABLES:
        records = raw.get(table, [])
        if records is None:
            records = []
        if not isinstance(records, list):
            raise ValueError(f"{table} table must be a list")

        clean_records = []
        max_id = 0

        for index, record in enumerate(records, start=1):
            if not isinstance(record, dict):
                continue
            item = dict(record)
            record_id = item.get("id")
            if not isinstance(record_id, int) or record_id <= 0:
                record_id = index
                item["id"] = record_id
            max_id = max(max_id, record_id)
            clean_records.append(item)

        normalized[table] = clean_records
        normalized["meta"]["next_ids"][table] = max(
            normalized["meta"]["next_ids"].get(table, 1),
            max_id + 1,
        )

    return normalized


def init_db(path: Path = DB_PATH, force: bool = False) -> Path:
    """Inizializza il database NoSQL su file.

    Se `force=True`, il database viene ricreato da zero.
    Se il file esistente è corrotto o incompatibile, viene salvato in backup.
    """
    with DB_LOCK:
        if force and path.exists():
            path.unlink()

        if not path.exists():
            _atomic_write(path, _empty_db())
            return path

        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
            normalized = _normalize_db(raw)
            _atomic_write(path, normalized)
        except Exception:
            if path.exists():
                backup = _backup_path(path)
                try:
                    shutil.copy2(path, backup)
                except Exception:
                    # Se il backup fallisce, ricreiamo comunque il database.
                    pass
            _atomic_write(path, _empty_db())

        return path


def load_db(path: Path = DB_PATH) -> Dict[str, Any]:
    """Legge il database da disco, creando il file se necessario."""
    with DB_LOCK:
        if not path.exists():
            init_db(path=path, force=False)

        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
            return _normalize_db(raw)
        except Exception:
            # Se il file è corrotto, lo ricreiamo in modo sicuro.
            init_db(path=path, force=True)
            return _empty_db()


def save_db(data: Dict[str, Any], path: Path = DB_PATH) -> None:
    """Salva il database su disco."""
    with DB_LOCK:
        _atomic_write(path, _normalize_db(data))


def next_id(data: Dict[str, Any], table: str) -> int:
    """Restituisce il prossimo ID per una tabella."""
    current = int(data["meta"]["next_ids"].get(table, 1))
    data["meta"]["next_ids"][table] = current + 1
    return current


def to_json_text(value: Any) -> str:
    """Converte un valore Python in stringa JSON.

    Se è già una stringa JSON valida, viene lasciata invariata.
    """
    if value is None:
        return "[]"
    if isinstance(value, str):
        try:
            json.loads(value)
            return value
        except Exception:
            return json.dumps(value, ensure_ascii=False)
    return json.dumps(value, ensure_ascii=False)


def as_bool(value: Any) -> bool:
    """Normalizza un valore a bool."""
    return bool(value)


def find_by_id(records: Iterable[Dict[str, Any]], record_id: int) -> Dict[str, Any] | None:
    """Trova un record per id dentro una lista di dizionari."""
    for record in records:
        if record.get("id") == record_id:
            return record
    return None


def delete_by_id(records: list[Dict[str, Any]], record_id: int) -> bool:
    """Elimina un record dalla lista in-place."""
    for index, record in enumerate(records):
        if record.get("id") == record_id:
            del records[index]
            return True
    return False


def filter_records(records: Iterable[Dict[str, Any]], **criteria: Any) -> list[Dict[str, Any]]:
    """Filtra i record confrontando uguaglianze semplici."""
    result: list[Dict[str, Any]] = []
    for record in records:
        ok = True
        for key, expected in criteria.items():
            if expected is None:
                continue
            if record.get(key) != expected:
                ok = False
                break
        if ok:
            result.append(dict(record))
    return result


# ----------------------------------------------------------------------
# HUB SINGLETON
# ----------------------------------------------------------------------
def get_hub_state(path: Path = DB_PATH) -> Dict[str, Any]:
    """Ritorna lo stato corrente dell'hub (paired/admin/house_name/...)."""
    with DB_LOCK:
        db = load_db(path)
        return dict(db["meta"].get("hub", {}))


def set_hub_state(updates: Dict[str, Any], path: Path = DB_PATH) -> Dict[str, Any]:
    """Aggiorna lo stato dell'hub (merge superficiale)."""
    with DB_LOCK:
        db = load_db(path)
        hub = dict(db["meta"].get("hub", {}))
        for k, v in updates.items():
            hub[k] = v
        db["meta"]["hub"] = hub
        save_db(db, path)
        return hub


def factory_reset(path: Path = DB_PATH, *, factory_code: str | None = None) -> Dict[str, Any]:
    """Svuota completamente il database e marca l'hub come non accoppiato.

    Conserva (o rigenera) un `factory_code` da mostrare sull'hub fisico
    per consentire un nuovo pairing.
    """
    with DB_LOCK:
        fresh = _empty_db()
        if factory_code:
            fresh["meta"]["hub"]["factory_code"] = factory_code
        _atomic_write(path, fresh)
        return fresh["meta"]["hub"]
