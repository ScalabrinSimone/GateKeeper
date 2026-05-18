# 🔐 Sicurezza

## Stato Attuale

> ⚠️ **L'autenticazione non è ancora stata implementata.** Il backend al momento non verifica le password né protegge gli endpoint.

### Cosa è già presente

- Le password vengono **hashate** con Werkzeug (`generate_password_hash`) al momento della creazione dell'utente
- I modelli Pydantic includono campi per email, ruolo e UUID
- L'architettura del sistema non espone porte direttamente su Internet

### Cosa manca

- ❌ **Nessun endpoint di login**
- ❌ **Nessuna verifica password** (le password hashate non vengono mai confrontate)
- ❌ **Nessun JWT o token di sessione**
- ❌ **Nessun middleware di autenticazione** sugli endpoint
- ❌ **Nessun rate limiting**
- ❌ **Nessun controllo di accesso basato su ruoli** (RBAC)

## Accesso Remoto

L'accesso remoto al sistema è progettato per avvenire tramite **Cloudflare Tunnel**, che garantisce:

- Connessione **HTTPS cifrata** senza esporre il Raspberry Pi su Internet
- **Nessun port forwarding** necessario sul router
- **Nessuna VPN** richiesta dall'utente finale
- Protezione da attacchi diretti all'IP del dispositivo

> 🔒 Il Raspberry Pi non è mai raggiungibile direttamente dall'esterno: tutto il traffico passa attraverso Cloudflare, che fa da proxy sicuro.

## Architettura di Sicurezza Prevista

```
App Flutter → HTTPS → Cloudflare Tunnel → Raspberry Pi (localhost:8000)
                    ↕
               Cloudflare Proxy
                    ↕
               JWT Authentication (da implementare)
```

## Piani Futuri

### 1. Autenticazione JWT
- Endpoint `/auth/login` con verifica password
- Generazione token JWT con scadenza configurabile
- Middleware di autenticazione su tutti gli endpoint protetti
- Refresh token per sessioni lunghe

### 2. Controllo Ruoli (RBAC)
- Ruoli: `admin`, `adult`, `child`
- Permessi differenziati per ruolo
- Admin: accesso completo
- Adulto: visualizzazione e notifiche
- Bambino: accesso limitato, monitoraggio

### 3. Sicurezza della Comunicazione
- HTTPS obbligatorio via Cloudflare Tunnel
- CORS configurato per sole origini consentite
- Headers di sicurezza (HSTS, CSP, X-Frame-Options)

### 4. Protezione del Database
- Backup automatici del file `nosql_db.json`
- Crittografia dei dati sensibili a riposo
- Sanitizzazione input in tutti gli endpoint

### 5. Hardening del Raspberry Pi
- Firewall locale (iptables/nftables)
- Disabilitazione servizi non necessari
- Aggiornamenti automatici di sicurezza
- Monitoraggio tentativi di accesso non autorizzati

## Dipendenze di Sicurezza

Le seguenti librerie sono nei requisiti ma **non ancora attive** nel runtime:

| Libreria | Scopo |
|---|---|
| `passlib[bcrypt]` | Hashing password avanzato |
| `python-jose[cryptography]` | JWT token |
| `python-multipart` | Form data parsing |
| `pydantic-settings` | Configurazione sicura |
