# ccm — Claude Code Manager

Tutte le sessioni di [Claude Code](https://claude.com/claude-code) in un'unica finestra di terminale, una scheda per sessione, con lo stato di ciascuna a colpo d'occhio e notifiche sul desktop quando una sessione ha bisogno di te.

Sotto c'è tmux, con socket e configurazione dedicati (`tmux -L ccm`): non interferisce con altri usi di tmux. Le sessioni restano vive anche chiudendo la finestra.

## Requisiti

Linux con GNOME (testato su Ubuntu 24.04, Wayland), gnome-terminal, `tmux`, `jq`, `notify-send`, Claude Code installato in `~/.local/bin/claude`.

```
sudo apt install tmux jq libnotify-bin
```

## Installazione

```
git clone https://github.com/davidecat/ccm.git ~/ccm && ~/ccm/install.sh
```

`install.sh` si può rilanciare senza danni:

- collega `~/.local/bin/ccm` e `~/.config/ccm/tmux.conf` ai file del repository;
- installa l'icona "Claude Sessioni";
- aggiunge gli hook di ccm a `~/.claude/settings.json` (backup in `settings.json.bak-ccm`), senza toccare altri hook;
- imposta la scorciatoia GNOME **Super+C**.

## Uso

| Comando | Cosa fa |
| --- | --- |
| Super+C / icona "Claude Sessioni" | Apre la finestra delle sessioni |
| `ccm` | Come sopra, da terminale (dentro ccm: lista delle sessioni) |
| `ccm new [-n NOME] [DIR] [-- ARGOMENTI_CLAUDE]` | Nuova sessione (default: cartella corrente) |
| `ccm resume [DIR]` | Nuova scheda con l'elenco delle conversazioni da riprendere |
| `ccm ls` | Elenco delle sessioni con stato |
| `ccm help` | Tutti i comandi |

Dentro la finestra:

| Tasto | Azione |
| --- | --- |
| F2 | Lista delle sessioni con stato e cartella |
| F3 | Nuova sessione (nome e cartella) |
| F4 | Chiude la sessione corrente |
| F5 / F6 | Scheda precedente / successiva |
| F7 | Rinomina la scheda |
| Ctrl+L | Ridisegna Claude se il testo appare spezzato |
| Click sulle schede | Cambia sessione |
| Shift + trascinare | Selezione normale del terminale |

Stato delle schede: **?** su giallo = aspetta una tua risposta · **◐** blu = sta lavorando · **✔** verde = ha finito.

## Come funziona

- **Stato:** gli hook di Claude Code (`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `Notification`, `Stop`, `SessionEnd`) chiamano `ccm hook EVENTO`, che scrive lo stato nell'opzione tmux `@cc_state` della scheda. Fuori da ccm l'hook non fa nulla.
- **Notifiche:** `notify-send` con il pulsante "Apri", che riporta alla scheda giusta.
- **Primo piano su Wayland:** non si può portare avanti una finestra esistente, quindi `ccm open` apre una nuova finestra di gnome-terminal e fa `attach -d`, che chiude quella vecchia.
- **Ridimensionamento:** dopo un resize il disegno di Claude può andare fuori sincrono; l'hook tmux `client-resized` lancia `ccm redraw`, che aspetta 0,4 s di calma e manda Ctrl+L a ogni Claude.

## File

| File | Contenuto |
| --- | --- |
| `ccm` | Lo script |
| `tmux.conf` | Aspetto, colori, tasti, hook di ridimensionamento |
| `ccm.desktop` | Icona "Claude Sessioni" |
| `install.sh` | Installazione |

## Licenza

MIT — vedi [LICENSE](LICENSE).
