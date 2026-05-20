# 📖 Setup MkDocs Material

## Perché MkDocs Material?

Questa documentazione è costruita con **MkDocs Material** — un fork ricco di funzionalità
di MkDocs che aggiunge un tema moderno, componenti avanzati e un'esperienza di sviluppo
eccellente.

Le ragioni della scelta:

| Criterio | Motivazione |
|---|---|
| **Markdown puro** | Tutta la documentazione è in `.md` — semplice da scrivere e mantenere |
| **Tema moderno** | Material Design, responsive, dark/light mode integrata |
| **Componenti ricchi** | Admonition, tabs, grids, code blocks con copia, diagrammi Mermaid |
| **Navigazione SPA** | Caricamento istantaneo delle pagine senza reload |
| **Personalizzabile** | CSS e JS custom per il tema GateKeeper |
| **Deploy gratuito** | GitHub Pages in un comando |
| **Zero dipendenze JS** | Non serve Node.js — solo Python |

---

## Struttura della documentazione

```
GateKeeper/
├── mkdocs.yml              # Configurazione principale
├── docs/
│   ├── index.md            # Home page
│   ├── assets/             # Immagini, logo, circuiti
│   ├── stylesheets/
│   │   ├── extra.css       # Tema GateKeeper personalizzato
│   │   └── extra.js        # Animazioni scroll, barra progresso
│   ├── panoramica/         # Idea, architettura, componenti
│   ├── parte-tecnica/      # Backend, DB, hardware, Flutter, sicurezza
│   ├── guida-utente/       # Installazione, primo avvio, notifiche
│   ├── sviluppo/           # Roadmap
│   └── problemi/           # Sfide tecniche e soluzioni
└── requirements.txt        # mkdocs-material + plugin
```

---

## Installazione

=== "pip (standard)"
    ```bash
    # Installa MkDocs Material e i plugin usati
    pip install mkdocs-material
    pip install mkdocs-minify-plugin  # compressione HTML opzionale
    
    # Oppure con il file requirements.txt della root:
    pip install -r requirements.txt
    ```

=== "Con virtual environment (consigliato)"
    ```bash
    python -m venv venv-docs
    source venv-docs/bin/activate   # Linux/macOS
    # oppure: venv-docs\Scripts\activate  (Windows)
    
    pip install mkdocs-material
    ```

---

## Comandi principali

```bash
# Avvia il server di sviluppo locale con live reload
mkdocs serve
# → http://127.0.0.1:8000

# Build statica (genera la cartella site/)
mkdocs build

# Deploy su GitHub Pages (richiede repo GitHub)
mkdocs gh-deploy
# → crea branch gh-pages e pubblica automaticamente
```

---

## Configurazione `mkdocs.yml`

Il file `mkdocs.yml` è la configurazione centrale. Le parti più importanti:

### Tema e palette

```yaml
theme:
  name: material
  palette:
    - scheme: slate          # Modalità scura (default GateKeeper)
      primary: custom        # Usa --md-primary-fg-color da CSS
      accent: custom
    - scheme: default        # Modalità chiara
      primary: custom
      accent: custom
  font:
    text: Inter              # Font moderno, leggibile
    code: JetBrains Mono     # Font monospace per il codice
```

### Feature importanti

```yaml
features:
  - navigation.instant          # SPA — nessun reload tra pagine
  - navigation.instant.progress # Barra caricamento
  - navigation.tabs             # Tab orizzontali in alto
  - navigation.tabs.sticky      # Tab sempre visibili
  - content.code.copy           # Pulsante copia codice
  - content.code.annotate       # Annotazioni nei blocchi codice
  - search.highlight            # Evidenzia ricerca
  - header.autohide             # Header si nasconde allo scroll
```

### Estensioni Markdown

```yaml
markdown_extensions:
  - admonition                  # Box note/warning/tip
  - pymdownx.superfences        # Code blocks avanzati + Mermaid
  - pymdownx.tabbed             # Tab nei contenuti
  - pymdownx.details            # Blocchi espandibili
  - pymdownx.emoji              # Emoji :material-check:
  - attr_list                   # Attributi HTML su elementi MD
  - md_in_html                  # Markdown dentro HTML div
```

---

## Personalizzazione tema GateKeeper

Il tema usa variabili CSS custom per la palette GateKeeper.
Il file `docs/stylesheets/extra.css` contiene:

=== "Variabili colori"
    ```css
    :root {
      --gk-ink-black:     #0D1117;
      --gk-charcoal-blue: #41474E;
      --gk-stormy-teal:   #00767A;
      --gk-orange:        #FFA400;
      --gk-lavender:      #F0E2E7;
    }
    
    [data-md-color-scheme="slate"] {
      --md-primary-fg-color: var(--gk-stormy-teal);
      --md-accent-fg-color:  var(--gk-orange);
    }
    ```

=== "Hero section"
    ```css
    /* Sfondo sfumato radiale per la home page */
    .gk-hero {
      background: radial-gradient(
        ellipse at 50% 0%,
        rgba(0, 118, 122, 0.14) 0%,
        transparent 70%
      );
    }
    /* Titolo con gradiente */
    .gk-hero h1 {
      background: linear-gradient(
        135deg, var(--gk-stormy-teal), var(--gk-lavender)
      );
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    ```

=== "Animazioni scroll"
    ```css
    /* Elementi che appaiono allo scroll */
    .gk-animate {
      opacity: 0;
      transform: translateY(28px);
      transition: opacity 0.55s ease, transform 0.55s ease;
    }
    .gk-animate.gk-visible {
      opacity: 1;
      transform: translateY(0);
    }
    ```

---

## Animazioni con IntersectionObserver

Le animazioni di scroll "fade-in-up" sono gestite da `docs/stylesheets/extra.js`
tramite l'API nativa **IntersectionObserver** del browser — senza librerie esterne.

**Come funziona:**

```javascript
// 1. Crea un observer che guarda gli elementi .gk-animate
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add("gk-visible"); // attiva CSS transition
      observer.unobserve(entry.target);          // smette di guardarlo
    }
  });
}, { threshold: 0.12 });

// 2. Osserva tutti gli elementi con classe .gk-animate
document.querySelectorAll(".gk-animate").forEach((el) => {
  observer.observe(el);
});
```

**Uso nei file Markdown:**

```html
<div class="gk-stat gk-animate">
  <span class="gk-stat-value">3</span>
  <span class="gk-stat-label">Layer software</span>
</div>
```

!!! tip "Navigazione SPA"
    MkDocs Material con `navigation.instant` carica le pagine come una SPA.
    Il file `extra.js` gestisce anche il caso di navigazione tra pagine
    riosservando gli elementi `.gk-animate` dopo ogni cambio pagina.

---

## Barra di progresso scroll

La barra colorata in cima alla pagina (gradiente teal → orange) è implementata
con puro CSS + JS senza librerie:

```javascript
// Crea la barra dinamicamente
const bar = document.createElement("div");
bar.className = "gk-scroll-progress";
document.body.appendChild(bar);

// Aggiorna la larghezza in base alla posizione di scroll
window.addEventListener("scroll", () => {
  const pct = (scrollY / (docHeight - windowHeight)) * 100;
  bar.style.width = pct + "%";
});
```

```css
.gk-scroll-progress {
  position: fixed;
  top: 0; left: 0;
  height: 3px;
  background: linear-gradient(90deg, #00767A, #FFA400);
  z-index: 9999;
  transition: width 0.1s linear;
}
```

---

## Diagrammi Mermaid

MkDocs Material supporta Mermaid nativo. Esempi usati nel progetto:

=== "Sequence diagram"
    ````markdown
    ```mermaid
    sequenceDiagram
        actor U as Utente
        participant RFID as RFID Reader
        RFID->>API: tag rilevato
        API->>APP: notifica
    ```
    ````

=== "Flow diagram"
    ````markdown
    ```mermaid
    graph TD
        A[RFID] --> B[Event Engine]
        B --> C[Notifica]
    ```
    ````

=== "Architettura"
    ````markdown
    ```mermaid
    graph TD
        subgraph HUB["Raspberry Pi"]
            API[FastAPI]
            DB[(JSON DB)]
        end
    ```
    ````

---

## Deploy su GitHub Pages

```bash
# Una volta configurato il repo GitHub:
mkdocs gh-deploy

# Oppure con GitHub Actions (automatico ad ogni push su main):
# vedi .github/workflows/docs.yml
```

```yaml
# .github/workflows/docs.yml
# TODO: aggiungi questo file se vuoi deploy automatico
name: Deploy docs
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.x' }
      - run: pip install mkdocs-material mkdocs-minify-plugin
      - run: mkdocs gh-deploy --force
```

---

## requirements.txt documentazione

```txt
mkdocs-material>=9.5
mkdocs-minify-plugin>=0.8  # opzionale — comprime HTML/CSS/JS
```

Per installare:

```bash
pip install -r requirements.txt
```

<!-- TODO: verifica che requirements.txt nella root contenga queste dipendenze -->
