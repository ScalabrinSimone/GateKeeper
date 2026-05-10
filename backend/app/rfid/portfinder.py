import platform
import serial.tools.list_ports

def get_port():
    # 1. prova auto-detect
    ports = serial.tools.list_ports.comports()
    for port in ports:
        desc = port.description.lower()
        if "ch340" in desc or "ch910" in desc or "usb serial" in desc:
            print("Auto-detected:", port.device)
            return port.device

    # 2. fallback per OS
    system = platform.system()

    if system == "Windows":
        return "COM3"
    elif system == "Linux":
        return "/dev/ttyUSB0"
    elif system == "Darwin":
        return "/dev/tty.usbserial-0001"

    raise Exception("Nessuna porta trovata")