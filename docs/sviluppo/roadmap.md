# 🚀 Roadmap

## Stato Attuale

Il progetto è in fase di sviluppo intermedia. Le funzionalità core sono implementate ma diverse integrazioni sono ancora in corso.

## ✅ Completato

### Backend
- [x] API REST completa (CRUD per utenti, dispositivi, log, eventi)
- [x] Persistenza JSON NoSQL thread-safe
- [x] Integrazione lettore RFID UHF (seriale)
- [x] Integrazione scanner BLE (bluetooth)
- [x] Avvio unificato con `run_all.py`

### App Flutter
- [x] UI completa con 6 schermate principali
- [x] Navigazione responsive (sidebar desktop + bottom nav mobile)
- [x] Tema chiaro/scuro personalizzato
- [x] Internazionalizzazione italiano/inglese
- [x] Struttura a provider (ChangeNotifier)

## 🔄 In Corso

### Backend
- [ ] Autenticazione JWT (endpoint login, middleware)
- [ ] Verifica password (hash → confronto)
- [ ] Controllo accesso basato su ruoli
- [ ] Documentazione API con Swagger personalizzata
- [ ] Test automatici

### App Flutter
- [ ] Collegamento API reale (rimpiazzare dati mock)
- [ ] Login reale con backend
- [ ] Persistenza token JWT (flutter_secure_storage)

### Hardware
- [ ] Associazione utente-phone via BLE
- [ ] Calibrazione raggio RFID/BLE

## 📅 Da Fare

### Backend
- [ ] Rate limiting e protezione endpoint
- [ ] Logging strutturato
- [ ] WebSocket per notifiche in tempo reale
- [ ] Migrazione a PostgreSQL (opzionale)
- [ ] Dockerizzazione

### App Flutter
- [ ] Notifiche push (FCM)
- [ ] Widget iOS/Android nativi (Live Activities)
- [ ] Test su dispositivi fisici
- [ ] Pubblicazione su store

### Deploy
- [ ] Configurazione Cloudflare Tunnel
- [ ] Script di deploy automatico
- [ ] Backup automatico database
- [ ] Monitoraggio e alert di sistema

## 🎯 Obiettivi Futuri

### Short-term
1. Autenticazione funzionante con JWT
2. App Flutter collegata al backend reale
3. Test end-to-end del flusso completo

### Medium-term
1. Notifiche push in tempo reale
2. Dashboard di monitoraggio
3. Multi-casa e multi-utente avanzato

### Long-term
1. Integrazione assistenti vocali (Alexa, Google Home)
2. Riconoscimento oggetti via AI/computer vision
3. Community e plugin di terze parti

## Come Contribuire

1. Fai un fork del repository
2. Crea un branch per la tua feature (`feature/nome-feature`)
3. Fai commit delle modifiche
4. Apri una Pull Request

Consulta la sezione [Problemi](../problemi/index.md) per le sfide tecniche e soluzioni adottate durante lo sviluppo.
