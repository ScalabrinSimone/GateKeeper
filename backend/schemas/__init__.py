"""
schemas/ — Pydantic schemas per la validazione request/response.

Differenza tra Schema e Modello ORM:
- Modello ORM (models/): mappa una classe Python su una tabella SQL.
- Schema Pydantic (schemas/): definisce la forma dei dati JSON
  in entrata (request body) e in uscita (response).

Convenzione naming:
- FooCreate  — dati necessari per creare un Foo (POST body)
- FooUpdate  — dati opzionali per aggiornare un Foo (PATCH body)
- FooRead    — dati restituiti nelle risposte (GET response)
"""
