#!/usr/bin/env bash
# Installa ccm per l'utente corrente. Si può rilanciare: ogni passo salta ciò che è già a posto.
#   - ~/.local/bin/ccm e ~/.config/ccm/tmux.conf come link ai file di questo repository
#   - icona "Claude Sessioni" in ~/.local/share/applications
#   - hook di Claude Code in ~/.claude/settings.json, o in $CLAUDE_CONFIG_DIR (backup in settings.json.bak-ccm)
#   - scorciatoia GNOME Super+C
set -euo pipefail

REPO=$(cd "$(dirname "$0")" && pwd)
EVENTS=(SessionStart UserPromptSubmit PreToolUse Notification Stop SessionEnd)

for c in tmux jq notify-send; do
  command -v "$c" >/dev/null || { echo "Manca $c: sudo apt install $c" >&2; exit 1; }
done

link() {  # link SORGENTE DESTINAZIONE
  mkdir -p "$(dirname "$2")"
  if [[ -e $2 && ! -L $2 ]]; then mv "$2" "$2.bak-ccm"; echo "  salvato il vecchio $2 in $2.bak-ccm"; fi
  ln -sfn "$1" "$2"
  echo "  $2 -> $1"
}

echo "File:"
link "$REPO/ccm" "$HOME/.local/bin/ccm"
link "$REPO/tmux.conf" "$HOME/.config/ccm/tmux.conf"
mkdir -p "$HOME/.local/share/applications"
cp "$REPO/ccm.desktop" "$HOME/.local/share/applications/ccm.desktop"
echo "  icona Claude Sessioni installata"

echo "Hook di Claude Code:"
SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"  # con CLAUDE_CONFIG_DIR: hook in quella configurazione
mkdir -p "$(dirname "$SETTINGS")"
[[ -f $SETTINGS ]] || echo '{}' >"$SETTINGS"
events_json=$(printf '%s\n' "${EVENTS[@]}" | jq -R . | jq -s .)
# Aggiunge "ccm hook EVENTO" solo agli eventi che non lo hanno già; gli altri hook restano intatti
new=$(jq --argjson ev "$events_json" '
  reduce $ev[] as $e (.;
    if ([.hooks[$e][]?.hooks[]?.command // empty] | any(test("ccm hook"))) then .
    else .hooks[$e] += [{hooks: [{type: "command", command: ("$HOME/.local/bin/ccm hook " + $e), timeout: 5}]}]
    end)' "$SETTINGS")
if [[ $new == "$(jq . "$SETTINGS")" ]]; then
  echo "  già presenti"
else
  cp "$SETTINGS" "$SETTINGS.bak-ccm"
  printf '%s\n' "$new" >"$SETTINGS"
  echo "  aggiunti (backup: $SETTINGS.bak-ccm)"
fi

echo "Scorciatoia Super+C:"
if command -v gsettings >/dev/null && gsettings list-schemas | grep -qx org.gnome.settings-daemon.plugins.media-keys; then
  BASE=org.gnome.settings-daemon.plugins.media-keys
  K=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ccm/
  list=$(gsettings get $BASE custom-keybindings)
  if [[ $list != *"$K"* ]]; then
    if [[ $list == "@as []" || $list == "[]" ]]; then list="['$K']"; else list="${list%]}, '$K']"; fi
    gsettings set $BASE custom-keybindings "$list"
  fi
  S="$BASE.custom-keybinding:$K"
  gsettings set "$S" name 'Claude Sessioni'
  gsettings set "$S" command "$HOME/.local/bin/ccm open"
  gsettings set "$S" binding '<Super>c'
  echo "  impostata"
else
  echo "  GNOME non trovato: assegna a mano un tasto al comando 'ccm open'"
fi

echo "Fatto. Apri ccm con Super+C oppure con il comando: ccm"
