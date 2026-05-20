# 🌍 Traduzione Documentazione (i18n MkDocs)

## Il problema

Durante lo sviluppo della documentazione abbiamo cercato un modo per supportare
**italiano e inglese** nella stessa build MkDocs, con un toggle visibile nell'interfaccia
per cambiare lingua al volo — simile a come funziona la documentazione ufficiale
di MkDocs Material.

---

## Cosa abbiamo trovato

### Opzione 1 — Plugin `i18n` ufficiale (MkDocs Material Insiders)

Il plugin `i18n` nativo di MkDocs Material permette di avere più lingue nella stessa build:
- Toggle lingua nell'header
- URL localizzati (`/it/`, `/en/`)
- Fallback automatico alla lingua di default

**Problema:** il plugin `i18n` è disponibile solo con
[MkDocs Material Insiders](https://squidfunk.github.io/mkdocs-material/insiders/) —
il piano a pagamento che si ottiene sponsorizzando il progetto su GitHub Sponsors
(~15$/mese o una tantum).

Per un progetto scolastico/educativo non era appropriato investire in una sponsorship.

---

### Opzione 2 — Plugin `mkdocs-static-i18n` (gratuito, community)

[`mkdocs-static-i18n`](https://github.com/ultrabug/mkdocs-static-i18n) è un plugin
community gratuito che implementa la multi-lingua per MkDocs.

**Come funziona:**
```
docs/
  index.it.md    ← versione italiana
  index.en.md    ← versione inglese
  index.md       ← fallback (default)
```

```yaml
# mkdocs.yml
plugins:
  - i18n:
      default_language: it
      languages:
        it:
          name: Italiano
          build: true
        en:
          name: English
          build: true
```

**Problema riscontrato:** nella versione di MkDocs Material 9.5.x che usiamo
(pinnata per evitare il warning su MkDocs 2.0), il plugin `mkdocs-static-i18n`
generava conflitti con le estensioni PyMdown e il tema Material
causando build instabili.

---

### Opzione 3 — Build separata per lingua

Creare due siti separati (`/it/` e `/en/`) con due `mkdocs.yml` distinti e
pubblicarli in sottocartelle su GitHub Pages. Funziona ma richiede doppia manutenzione
di tutti i file `.md`.

**Problema:** duplicazione totale del contenuto — ogni modifica va fatta due volte.
Per un progetto in evoluzione rapida è unsostenibile.

---

## Soluzione adottata

Abbiamo deciso di mantenere la documentazione **in italiano** — lingua del team —
come scelta pragmatica:

1. **Il team è italiano** → la documentazione in italiano è più chiara per chi sviluppa
2. **Zero manutenzione doppia** → una sola versione da tenere aggiornata
3. **Codice commentato in italiano** → coerenza tra docs e codice
4. **GitHub ha già un'interfaccia inglese** → chi legge sa già leggere in italiano

!!! info "Nota per il futuro"
    Se il progetto dovesse crescere o richiedere internazionalizzazione, le opzioni sono:
    
    1. Sponsorizzare MkDocs Material Insiders per il plugin `i18n` ufficiale
    2. Riesaminare `mkdocs-static-i18n` con una versione più recente di MkDocs
    3. Usare un servizio di traduzione automatica (es. DeepL API) per generare la versione EN

---

## Cosa abbiamo implementato invece

Per migliorare l'esperienza degli utenti non italofoni, abbiamo:

- Aggiunto **commenti in inglese** nelle sezioni tecniche più complesse
- Usato **nomi di variabili e funzioni in inglese** nel codice
- Mantenuto la **documentazione API** (`/docs` Swagger) in inglese (generata da FastAPI)
- Il **README.md** principale del repository è scritto **in italiano** con sezioni bilingue

---

## Approfondimento tecnico: come funziona il plugin i18n

Se in futuro vuoi implementare la multi-lingua, ecco come farlo con `mkdocs-static-i18n`:

```bash
pip install mkdocs-static-i18n
```

```yaml
# mkdocs.yml — configurazione multi-lingua
plugins:
  - search:
      lang: [it, en]
  - i18n:
      default_language: it
      default_language_only: false
      docs_structure: suffix  # usa .it.md / .en.md
      languages:
        - locale: it
          name: Italiano 🇮🇹
          build: true
          default: true
          nav_translations:
            Home: Home
            Hardware: Hardware
        - locale: en
          name: English 🇬🇧
          build: true
          nav_translations:
            Home: Home
            Hardware: Hardware
```

```
docs/
  index.it.md          ← italiano (default)
  index.en.md          ← inglese
  parte-tecnica/
    hardware.it.md
    hardware.en.md
```

!!! warning "Compatibilità"
    Verifica sempre la compatibilità tra la versione di `mkdocs-static-i18n` e
    `mkdocs-material` prima di aggiornare. Le versioni più recenti di entrambi
    tendono ad essere più compatibili.
