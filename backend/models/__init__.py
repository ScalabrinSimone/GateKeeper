# Questo file rende la cartella `models/` un package Python.
# Importa qui i modelli per renderli facilmente accessibili:
#   from models import User, RfidObject, GateEvent, Home
from models.user import User
from models.rfid_object import RfidObject
from models.gate_event import GateEvent
from models.home import Home

__all__ = ["User", "RfidObject", "GateEvent", "Home"]
