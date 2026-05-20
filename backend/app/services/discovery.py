"""Discovery LAN del Raspberry / hub.

Implementazione semplice basata su un listener UDP broadcast.
L'app invia un broadcast `GATEKEEPER_DISCOVER?` sulla porta UDP 51820 e
l'hub risponde con `GATEKEEPER_HUB|<host>:<api_port>|<paired>|<house_name>`.

Vantaggio: non richiede mDNS/Zeroconf (che su Windows può richiedere driver).
Limite: funziona solo dentro la stessa rete LAN.
"""

from __future__ import annotations

import json
import socket
import threading
from typing import Callable, Optional

DISCOVERY_PORT = 51820
DISCOVERY_MAGIC = "GATEKEEPER_DISCOVER?"
RESPONSE_PREFIX = "GATEKEEPER_HUB"


def _build_response(api_port: int, hub_info: dict) -> bytes:
    """Costruisce la risposta JSON da inviare al client che ha fatto discovery."""
    payload = {
        "kind": RESPONSE_PREFIX,
        "api_port": api_port,
        "paired": bool(hub_info.get("paired", False)),
        "house_name": hub_info.get("house_name"),
        "version": 1,
    }
    return json.dumps(payload).encode("utf-8")


def run_discovery_listener(
    *,
    api_port: int,
    get_hub_info: Callable[[], dict],
    stop_event: Optional[threading.Event] = None,
) -> None:
    """Avvia il listener UDP per le richieste di discovery.

    `get_hub_info` è una callable senza argomenti che ritorna lo stato hub.
    `stop_event`, se passato, interrompe il loop quando viene settato.
    """
    stop_event = stop_event or threading.Event()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    except Exception:
        pass

    try:
        sock.bind(("0.0.0.0", DISCOVERY_PORT))
    except OSError as exc:
        print(f"[DISCOVERY] Impossibile fare bind sulla porta {DISCOVERY_PORT}: {exc}")
        return

    sock.settimeout(1.0)
    print(f"[DISCOVERY] In ascolto su UDP {DISCOVERY_PORT}")

    while not stop_event.is_set():
        try:
            data, addr = sock.recvfrom(1024)
        except socket.timeout:
            continue
        except OSError:
            break

        try:
            message = data.decode("utf-8", errors="ignore").strip()
        except Exception:
            continue

        if not message.startswith(DISCOVERY_MAGIC):
            continue

        try:
            response = _build_response(api_port, get_hub_info())
            sock.sendto(response, addr)
            print(f"[DISCOVERY] Risposto a {addr}")
        except Exception as exc:
            print(f"[DISCOVERY] Errore risposta: {exc}")

    try:
        sock.close()
    except Exception:
        pass
    print("[DISCOVERY] Listener fermato")
