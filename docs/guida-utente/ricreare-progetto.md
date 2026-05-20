# 🔨 Ricreare il Progetto da Zero

Questa guida spiega come ricreare GateKeeper partendo dall'hardware fisico
fino ad avere il sistema completamente funzionante — passo dopo passo.

---

## Prerequisiti

### Hardware necessario

| Componente | Quantità | Note |
|---|---|---|
| Raspberry Pi 4 (4GB) | 1 | 2GB sufficiente per sviluppo |
| MicroSD 32GB+ (Classe 10/A2) | 1 | Raccomandato: SanDisk Endurance |
| Lettore RFID UHF USB | 1 | Chipset CH340/CH910 |
| Tag RFID UHF (EPC Gen2) | N | ~0,10€/cad su AliExpress |
| Alimentatore 5V/3A USB-C | 1 | Ufficiale RPi raccomandato |
| PC/Mac per configurazione | 1 | Qualsiasi sistema operativo |
| Telefono Android/iOS | 1 | Per l'app GateKeeper |

### Software necessario (PC)

- [Raspberry Pi Imager](https://www.raspberrypi.com/software/) — per flashare la SD
- [Flutter SDK](https://flutter.dev/docs/get-started/install) — per l'app
- [Python 3.11+](https://python.org) — per il backend
- [Git](https://git-scm.com) — per clonare il repository
- Editor: [VS Code](https://code.visualstudio.com) (consigliato)

---

## Fase 1 — Preparare il Raspberry Pi

### 1.1 Flashare il sistema operativo

1. Scarica e apri **Raspberry Pi Imager**
2. Scegli: **Raspberry Pi OS Lite (64-bit)** (senza desktop — più leggero)
3. Seleziona la MicroSD
4. Clicca ⚙️ **Impostazioni avanzate** e configura:
   - Hostname: `gatekeeper` (o quello che preferisci)
   - Abilita SSH con password o chiave pubblica
   - Configura Wi-Fi (SSID + password della tua rete)
   - Imposta username: `pi` e una password sicura
5. Scrivi l'immagine sulla SD

### 1.2 Primo accesso SSH

```bash
# Dal tuo PC — trova l'IP del Raspberry
# Opzione 1: ping tramite mDNS
ping gatekeeper.local

# Opzione 2: scansiona la rete locale
nmap -sn 192.168.1.0/24  # adatta alla tua subnet

# Connetti via SSH
ssh pi@gatekeeper.local  # oppure ssh pi@192.168.1.xxx
```

### 1.3 Aggiornamento sistema

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git python3-pip python3-venv
```

---

## Fase 2 — Clonare il Repository

```bash
# Sul Raspberry Pi (via SSH)
cd ~
git clone https://github.com/ScalabrinSimone/GateKeeper.git
cd GateKeeper/backend
```

---

## Fase 3 — Configurare il Backend

### 3.1 Ambiente virtuale Python

```bash
python3 -m venv venv
source venv/bin/activate

# Installa le dipendenze
pip install -r requirements.txt
```

### 3.2 Configurazione email (opzionale ma consigliata)

```bash
# Copia il file di configurazione
cp .env.example .env
nano .env
```

Compila `.env`:
```ini
GK_SMTP_HOST=smtp.gmail.com
GK_SMTP_PORT=587
GK_SMTP_USER=tuo-account@gmail.com
GK_SMTP_PASSWORD=xxxx xxxx xxxx xxxx  # App Password Google
GK_SMTP_FROM=tuo-account@gmail.com
```

!!! tip "Come ottenere una App Password Gmail"
    1. Vai su [myaccount.google.com](https://myaccount.google.com)
    2. Sicurezza → Verifica in 2 passaggi (deve essere attiva)
    3. Sicurezza → Password per le app
    4. Scegli "Altra (nome personalizzato)" → scrivi "GateKeeper"
    5. Copia la password di 16 caratteri nel campo `GK_SMTP_PASSWORD`

### 3.3 Avvio manuale (test)

```bash
python run_all.py
```

Il backend:
- Inizializza il database JSON in `app/db/nosql_db.json`
- Stampa un QR code nel terminale con i dati di pairing
- Avvia il server FastAPI su `http://0.0.0.0:8000`
- Avvia RFID e BLE automaticamente dopo il pairing

---

## Fase 4 — Avvio automatico al boot

### 4.1 Creare un servizio systemd

```bash
sudo nano /etc/systemd/system/gatekeeper.service
```

```ini
[Unit]
Description=GateKeeper Backend
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/GateKeeper/backend
# TODO: aggiorna il percorso se necessario
ExecStart=/home/pi/GateKeeper/backend/python run_all.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# Abilita e avvia il servizio
sudo systemctl daemon-reload
sudo systemctl enable gatekeeper
sudo systemctl start gatekeeper

# Controlla lo stato
sudo systemctl status gatekeeper

# Vedi i log in tempo reale
sudo journalctl -u gatekeeper -f
```

---

## Fase 5 — Collegare il Lettore RFID

### 5.1 Collegamento fisico

1. Collega il lettore RFID UHF alla porta USB del Raspberry Pi
2. Il driver CH340 è incluso nel kernel Linux — nessuna installazione necessaria

### 5.2 Verificare il rilevamento

```bash
# Controlla che il dispositivo sia riconosciuto
ls /dev/ttyUSB*     # dovrebbe mostrare /dev/ttyUSB0 o simile
lsusb               # cerca "QinHeng Electronics CH340 serial converter"

# Opzionale: test lettura diretta
python3 -c "
import serial
with serial.Serial('/dev/ttyUSB0', 38400, timeout=1) as s:
    print('Porta aperta OK. Avvicina un tag RFID...')
    data = s.read(100)
    print('Ricevuto:', data.hex())
"
```

### 5.3 Permessi porta seriale

```bash
# Aggiungi l'utente al gruppo dialout per l'accesso alla seriale
sudo usermod -a -G dialout pi
# Richiede logout/login per avere effetto
```

---

## Fase 6 — Configurare Cloudflare Tunnel (accesso remoto)

!!! info "Perché Cloudflare Tunnel?"
    Il Cloudflare Tunnel crea un tunnel cifrato tra il Raspberry Pi e
    Internet — senza aprire porte sul router. L'app si connette
    tramite un URL HTTPS come `https://gatekeeper.tuo-dominio.com`.

### 6.1 Prerequisiti

- Account Cloudflare gratuito su [cloudflare.com](https://cloudflare.com)
- Un dominio gestito da Cloudflare (anche gratuito con Freenom/Cloudflare Registrar)

### 6.2 Installare cloudflared

```bash
# Sul Raspberry Pi
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb

# Autenticazione
cloudflared tunnel login
```

### 6.3 Creare il tunnel

```bash
# Crea il tunnel
cloudflared tunnel create gatekeeper

# Crea il file di configurazione
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

```yaml
# ~/.cloudflared/config.yml
# TODO: sostituisci con il tuo tunnel ID e dominio
tunnel: IL-TUO-TUNNEL-ID
credentials-file: /home/pi/.cloudflared/IL-TUO-TUNNEL-ID.json

ingress:
  - hostname: gatekeeper.tuo-dominio.com   # TODO: il tuo dominio
    service: http://localhost:8000
  - service: http_status:404
```

```bash
# Associa il sottodominio al tunnel (crea il record DNS)
cloudflared tunnel route dns gatekeeper gatekeeper.tuo-dominio.com

# Avvia (test)
cloudflared tunnel run gatekeeper

# Servizio systemd per avvio automatico
sudo cloudflared service install
sudo systemctl enable cloudflared
```

---

## Fase 7 — Installare l'App Flutter

### 7.1 Prerequisiti PC

```bash
# Installa Flutter (segui la guida ufficiale per il tuo OS)
# https://flutter.dev/docs/get-started/install

# Verifica installazione
flutter doctor
```

### 7.2 Build e run

```bash
cd GateKeeper/app

# Dipendenze
flutter pub get

# Avvia su dispositivo connesso o emulatore
flutter run

# Build APK (Android)
flutter build apk --release

# Build per Windows
flutter build windows --release

# Build per macOS
flutter build macos --release
```

### 7.3 Prima configurazione nell'app

1. Apri l'app → **"Nuovo hub"**
2. Scegli **"Scansiona QR"** e inquadra il QR nel terminale del Raspberry
   oppure **"Inserisci URL manualmente"** con l'indirizzo del tunnel
3. Segui il **wizard di setup** per creare l'account admin
4. Inserisci nome casa, username, email e password
5. Verifica l'email con il codice a 6 cifre ricevuto
6. Il sistema è operativo ✓

---

## Fase 8 — Registrare il Bluetooth del telefono

!!! warning "Passo fondamentale"
    Senza questo passo il sistema non può associare le uscite RFID al tuo utente.

1. Nell'app, vai su **Impostazioni** → sezione **"Bluetooth - Rilevamento presenza"**
2. Premi **"Cerca dispositivi BLE vicini"** — tieni il telefono vicino al Raspberry
3. Trova il tuo dispositivo nella lista e premi **"Sono io"**
4. Da questo momento il Raspberry associerà automaticamente gli eventi RFID al tuo account

---

## Fase 9 — Aggiungere oggetti RFID

1. Nell'app, vai su **Oggetti** → **"+"**
2. Assegna un nome all'oggetto (es. "Chiavi di casa")
3. Scegli la categoria e, se vuoi, marca come **Essenziale**
4. Premi **"Scansiona tag"** e avvicina il tag RFID al lettore
5. Salva — l'oggetto è ora tracciato ✓

---

## Risoluzione problemi comuni

??? question "Il lettore RFID non viene rilevato"
    ```bash
    # Controlla se è connesso
    lsusb | grep -i "ch340\|ch910\|serial"
    # Se non compare, prova un altro cavo USB o porta
    # Verifica i permessi: sudo usermod -a -G dialout pi
    ```

??? question "Il BLE scanner non avvia"
    ```bash
    # Controlla che il Bluetooth sia attivo
    hciconfig
    # Se hci0 è DOWN: sudo hciconfig hci0 up
    # Installa bleak: pip install bleak
    ```

??? question "L'app non si connette all'hub"
    - Verifica che backend sia in esecuzione: `sudo systemctl status gatekeeper`
    - Controlla che il tunnel Cloudflare funzioni: `cloudflared tunnel info`
    - In locale: usa l'IP LAN direttamente (es. `http://192.168.1.100:8000`)

??? question "Non ricevo le email"
    - Controlla `backend/outbox.log` — il codice è sempre lì
    - Verifica che `.env` sia nella cartella `backend/` con le credenziali corrette
    - Controlla la cartella spam su Gmail
    - Assicurati che la 2FA sia attiva e che l'App Password sia corretta

<!-- TODO: aggiungi altri problemi comuni man mano che li incontri -->
