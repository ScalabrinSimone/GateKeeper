//Enumerazioni di dominio condivise.

enum UserRole { admin, adult, child }

enum HomeStatus { safe, alert, away }

//Categoria oggetto: ricalca i tipi previsti dal backend (devices.category).
enum ObjectCategory { keys, wallet, umbrella, bag, phone, other }

//Direzione passaggio: allineata al campo backend events.direction.
enum GateDirection { entry, exit }

//Tipo evento: ricalca events.event_type.
enum EventType { entry, exit, risk, system }

//Severità interfaccia (UI only).
enum EventSeverity { info, warning, critical }
