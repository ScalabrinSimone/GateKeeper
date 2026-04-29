from pathlib import Path
import asyncio
import threading
from bleak import BleakScanner
from bleak.exc import BleakBluetoothNotAvailableError

# Scanner BLE semplice:
# - salva indirizzi MAC/identificatori univoci in ble.txt (una riga per indirizzo)
# - mantiene un set in-memory `SEEN` per evitare duplicati anche durante l'esecuzione
# - legge ble.txt all'avvio per evitare duplicati persistenti tra i riavvii

BLE_FILE = Path.cwd() / "ble.txt"
SEEN = set()
LOCK = threading.Lock()


def load_seen():
    """
    Carica gli indirizzi già salvati in `ble.txt` nel set `SEEN`.

    Questo evita di riscrivere indirizzi già presenti su disco
    quando lo scanner viene riavviato (dedupe persistente).
    """
    if BLE_FILE.exists():
        try:
            with BLE_FILE.open("r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line:
                        SEEN.add(line)
        except Exception:
            # Ignora errori di lettura non critici.
            pass


def append_address(addr: str) -> bool:
    """
    Aggiunge `addr` a `ble.txt` e al set `SEEN` in modo thread-safe.

    Restituisce True se l'indirizzo è stato scritto (era nuovo),
    False se era già presente o se c'è stato un errore di scrittura.
    """
    addr = addr.strip()
    with LOCK:
        if addr in SEEN:
            return False
        try:
            BLE_FILE.parent.mkdir(parents=True, exist_ok=True)
            with BLE_FILE.open("a", encoding="utf-8") as f:
                f.write(addr + "\n")
        except Exception:
            return False
        SEEN.add(addr)
        return True


def detection_callback(device, advertisement_data):
    """
    Callback invocata da Bleak quando viene rilevato un dispositivo.

    Estrae l'indirizzo (o identificatore) dal `device` e prova a registrarlo
    chiamando `append_address`. Se l'indirizzo è nuovo, stampa una notifica.
    """
    # `device.address` è il campo comune su molte piattaforme;
    # usiamo `identifier` come fallback quando presente.
    addr = getattr(device, "address", None) or getattr(device, "identifier", None)
    if not addr:
        return
    if append_address(addr):
        print(f"New device: {addr}")


async def run_scan(duration: float = None):
    """
    Routine principale che avvia la scansione BLE.

    - Carica gli indirizzi già visti con `load_seen()`.
    - Istanzia `BleakScanner`. Alcune versioni di `bleak` accettano una
      `detection_callback` nel costruttore; altre no. Per compatibilità
      proviamo ad usare il costruttore con callback quando disponibile.
    - Se la radio Bluetooth non è disponibile o è spenta, viene intercettata
      `BleakBluetoothNotAvailableError` e viene stampata una guida per la risoluzione.
    - Se la libreria non fornisce callback, viene eseguito un polling
      periodico (`poll_discovered`) per rileggere i dispositivi scoperti e
      chiamare `detection_callback` su ognuno.
    - `duration` opzionale permette di eseguire la scansione per N secondi;
      se non specificata, il processo resta in esecuzione fino a interruzione.
    """
    load_seen()
    # Proviamo a passare il callback al costruttore quando supportato.
    from inspect import signature
    try:
        params = signature(BleakScanner).parameters
        if 'detection_callback' in params:
            scanner = BleakScanner(detection_callback=detection_callback)
        else:
            scanner = BleakScanner()
    except Exception:
        scanner = BleakScanner()

    try:
        await scanner.start()
    except BleakBluetoothNotAvailableError as e:
        # Errore comune quando l'adattatore Bluetooth è spento o non presente.
        print("Bluetooth radio is not available or powered off!", e)
        """
        # Forniamo istruzioni utili all'utente per Windows e Raspberry Pi.
        print("If you're on Windows: enable Bluetooth in Settings and try again.")
        print("If you're on Raspberry Pi / Linux: ensure BlueZ is installed, the Bluetooth service is running, and the adapter is powered on.")
        print("Useful commands (Linux/Raspberry Pi):")
        print("  sudo systemctl start bluetooth")
        print("  sudo rfkill unblock bluetooth")
        print("  bluetoothctl power on")
        print("You may also need to run as root or grant capabilities: sudo setcap 'cap_net_raw+eip' $(which python3)")
        """
        return
    print("BLE scanner started. Writing unique addresses to", BLE_FILE)
    try:
        # Fallback: se non esiste un meccanismo di callback, eseguiamo polling.
        async def poll_discovered():
            while True:
                devices = []
                try:
                    if hasattr(scanner, 'get_discovered_devices') and callable(getattr(scanner, 'get_discovered_devices')):
                        devices = await scanner.get_discovered_devices()
                    else:
                        devices = list(getattr(scanner, 'discovered_devices', []))
                except Exception:
                    devices = list(getattr(scanner, 'discovered_devices', []))

                for d in devices:
                    try:
                        detection_callback(d, None)
                    except Exception:
                        # Ignora errori su singole elaborazioni del device
                        pass

                await asyncio.sleep(1.0)

        poll_task = asyncio.create_task(poll_discovered())

        if duration:
            await asyncio.sleep(duration)
        else:
            await asyncio.Event().wait()
    finally:
        if 'poll_task' in locals():
            poll_task.cancel()
            try:
                await poll_task
            except asyncio.CancelledError:
                pass
        await scanner.stop()
        print("Scanner stopped.")

"""
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    TENERE SOLO SE SI VUOLE TESTARE PER UN PO' DI SECONDI
            (python -m app.blescanner.scanner -d 60)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"""
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="BLE scanner that logs unique addresses to ble.txt")
    parser.add_argument("--duration", "-d", type=float, default=None, help="Scan duration in seconds (default: run indefinitely)")
    args = parser.parse_args()
    try:
        asyncio.run(run_scan(args.duration))
    except KeyboardInterrupt:
        print("Interrupted by user")
