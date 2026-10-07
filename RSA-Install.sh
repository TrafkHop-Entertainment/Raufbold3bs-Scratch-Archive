#!/usr/bin/env bash
# RSA-Install.sh – Raufbold3bs-Scratch-Archive: Spiele, Icons und Desktop-Einträge installieren
set -euo pipefail

# ---------------------------------------------------------------- Konfiguration
# Welcher Stand wird geholt? "HEAD" = immer die neueste Version des Standard-Branches.
# Zum Festpinnen einen Commit-Hash eintragen (oder beim Aufruf:
# GAMES_REF=<hash> ICONS_REF=<hash> ./RSA-Install.sh)
GAMES_REF="${GAMES_REF:-HEAD}"
ICONS_REF="${ICONS_REF:-HEAD}"

GAMES_BASE_URL="https://raw.githubusercontent.com/TrafkHop-Entertainment/Raufbold3bs-Scratch-Archive/${GAMES_REF}/Games"
ICONS_BASE_URL="https://raw.githubusercontent.com/TrafkHop-Entertainment/SourceHop-Images/${ICONS_REF}/Projects/RSA/Thumbnails"

INSTALL_DIR="${HOME}/.local/share/TrafkHopEntertainment/Raufbold3bs-Scratch-Archive"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_THEME_DIR="${HOME}/.local/share/icons/hicolor/256x256/apps"

# Fallback-Icon (aus dem aktuellen Icon-Theme), falls ein Spiel kein eigenes
# Thumbnail im SourceHop-Images-Repo hat.
FALLBACK_ICON_NAME="applications-games"

# Jede Zeile: "Dateiname.html|Icon-Dateiname.png|eindeutiger-slug|Anzeigename"
# - Der Slug wird für .desktop-Dateinamen und Icon-Theme-Namen genutzt
#   (keine Leerzeichen/Sonderzeichen, damit jede Desktop-Umgebung ihn sauber
#   verarbeitet).
# - Ein leeres Icon-Feld bedeutet: kein passendes Thumbnail im Thumbnails-
#   Ordner gefunden -> es wird FALLBACK_ICON_NAME verwendet.
GAMES=(
    "RSA _ auto v2.html|autov2.png|rsa-autov2|RSA – auto v2"
    "RSA _ Der Apfel und der Kürbis.html|derapfelundderkuerbis.png|rsa-apfel-kuerbis|RSA – Der Apfel und der Kürbis"
    "RSA _ Die 2 Cops.html|die2cops.png|rsa-die2cops|RSA – Die 2 Cops"
    "RSA _ Die Abenteuer von Ritter Goffy und seinem schlauen Kollegen Blufi 5 The game.html|goffy.png|rsa-goffy|RSA – Die Abenteuer von Ritter Goffy"
    "RSA _ Flappy Pyley.html|flappypyley.png|rsa-flappypyley|RSA – Flappy Pyley"
    "RSA _ grasi 1.4.3 (Costume overhaul 1) (basic jumping no hole).html|grasiv143.png|rsa-grasi143|RSA – grasi 1.4.3"
    "RSA _ Gras-Zupf Simulator (EarlyAccess) v.0.64.html|grasiv064.png|rsa-graszupf064|RSA – Gras-Zupf Simulator"
    "RSA _ Mayro rpg.html|sky.png|rsa-mayrorpg|RSA – Mayro RPG"
    "RSA _ Pyley Fang.html|pyleyfang.png|rsa-pyleyfang|RSA – Pyley Fang"
    "RSA _ Pyley Jump.html|pyleyjump.png|rsa-pyleyjump|RSA – Pyley Jump"
    "RSA _ Pyley Run 1.0.html|pyleyrun.png|rsa-pyleyrun|RSA – Pyley Run 1.0"
    "RSA _ Pyley's Adventures.html|bg.png|rsa-pyleysadventures|RSA – Pyley's Adventures"
    "RSA _ Pyley's Hunt.html|pyleyhunt.png|rsa-pyleyshunt|RSA – Pyley's Hunt"
    "RSA _ Retro Klavier.html|retroklavier.png|rsa-retroklavier|RSA – Retro Klavier"
    "RSA _ Sonnenpflicht.html|Sonnenpflicht.png|rsa-sonnenpflicht|RSA – Sonnenpflicht"
)

# ---------------------------------------------------------------- Hilfsfunktionen
info() { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[✓]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[!]\033[0m %s\n' "$*" >&2; }

need() {
    command -v "$1" >/dev/null 2>&1 || { err "'$1' fehlt. Bitte installieren (siehe Hinweis unten)."; MISSING=1; }
}

# Reiner Bash-URL-Encoder, byteweise über LC_ALL=C (funktioniert damit auch
# korrekt für mehrbytige UTF-8-Zeichen wie 'ü'), statt einzelner Sonderfälle
# wie im alten Skript.
urlencode() {
    local LC_ALL=C
    local string="$1" length=${#1} i c
    for (( i = 0; i < length; i++ )); do
        c="${string:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

# ---------------------------------------------------------------- Abhängigkeiten prüfen
MISSING=0
need wget
need xdg-open
if [ "$MISSING" -ne 0 ]; then
    cat >&2 <<'EOF'

Benötigte Pakete installieren, z. B.:
  Debian/Ubuntu/Mint : sudo apt install wget xdg-utils
  Fedora             : sudo dnf install wget xdg-utils
  Arch/Manjaro       : sudo pacman -S wget xdg-utils
EOF
    exit 1
fi

# ---------------------------------------------------------------- Zielordner vorbereiten
PARENT_DIR="$(dirname "$INSTALL_DIR")"   # .../TrafkHopEntertainment

if [ -L "$PARENT_DIR" ] && [ ! -d "$PARENT_DIR" ]; then
    err "${PARENT_DIR} ist ein kaputter Symlink (Ziel: $(readlink "$PARENT_DIR"))."
    exit 1
fi

if [ -d "$INSTALL_DIR" ]; then
    info "Zielordner existiert bereits: ${INSTALL_DIR}"
else
    info "Erstelle Zielordner: ${INSTALL_DIR}"
    mkdir -p "$INSTALL_DIR"
fi

mkdir -p "$DESKTOP_DIR" "$ICON_THEME_DIR"

if command -v xdg-user-dir >/dev/null 2>&1; then
    USER_DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
else
    USER_DESKTOP_DIR="${HOME}/Desktop"
fi

# ---------------------------------------------------------------- Staging-Ordner
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "Starting download in: $INSTALL_DIR"
echo ""

INSTALLED=0
SKIPPED_ICON=()

for entry in "${GAMES[@]}"; do
    IFS='|' read -r game_file icon_file slug title <<< "$entry"

    encoded_game="$(urlencode "$game_file")"
    game_url="${GAMES_BASE_URL}/${encoded_game}"

    staged_game="${BUILD_DIR}/${game_file}"

    echo "Downloading: $game_file ..."
    if ! wget -q --show-progress -O "$staged_game" "$game_url"; then
        err "Download fehlgeschlagen: $game_file ($game_url)"
        continue
    fi

    # Icon laden (falls im Thumbnails-Repo vorhanden), sonst Fallback vormerken
    staged_icon=""
    if [ -n "$icon_file" ]; then
        encoded_icon="$(urlencode "$icon_file")"
        icon_url="${ICONS_BASE_URL}/${encoded_icon}"
        staged_icon="${BUILD_DIR}/${slug}.png"
        echo "Downloading icon: $icon_file ..."
        if wget -q --show-progress -O "$staged_icon" "$icon_url" \
            && [ "$(head -c 4 "$staged_icon" | tail -c 3)" = "PNG" ]; then
            :
        else
            err "Icon-Download fehlgeschlagen oder ungültig: $icon_file ($icon_url) – nutze Fallback-Icon."
            rm -f "$staged_icon"
            staged_icon=""
            SKIPPED_ICON+=("$title")
        fi
    else
        SKIPPED_ICON+=("$title")
    fi

    # Spiel atomar installieren (erst unter temporärem Namen, dann mv)
    install -m 644 "$staged_game" "${INSTALL_DIR}/.${game_file}.new"
    mv -f "${INSTALL_DIR}/.${game_file}.new" "${INSTALL_DIR}/${game_file}"

    if ! cmp -s "$staged_game" "${INSTALL_DIR}/${game_file}"; then
        err "${game_file} im Zielordner stimmt nicht mit der neuen Version überein!"
        continue
    fi

    # Icon ins hicolor-Theme installieren (dort suchen App-Launcher nach dem
    # in Icon= angegebenen NAMEN, nicht nach einer in die .desktop-Datei
    # eingebetteten Grafik) UND zusätzlich in den Spieleordner kopieren,
    # damit dort direkt neben der .html-Datei auch ein Thumbnail liegt.
    icon_name="$FALLBACK_ICON_NAME"
    if [ -n "$staged_icon" ] && [ -f "$staged_icon" ]; then
        install -m 644 "$staged_icon" "${ICON_THEME_DIR}/${slug}.png"
        install -m 644 "$staged_icon" "${INSTALL_DIR}/${slug}.png"
        icon_name="$slug"
    fi

    # .desktop-Eintrag (Anwendungsmenü)
    desktop_file="${DESKTOP_DIR}/${slug}.desktop"
    desktop_entry="[Desktop Entry]
Type=Application
Name=${title}
Exec=xdg-open \"${INSTALL_DIR}/${game_file}\"
Icon=${icon_name}
StartupWMClass=${slug}
Terminal=false
Categories=Game;"

    printf '%s\n' "$desktop_entry" > "$desktop_file"
    chmod 644 "$desktop_file"

    # Desktop-Verknüpfung (falls ein Desktop-Ordner existiert)
    if [ -n "${USER_DESKTOP_DIR:-}" ] && [ -d "${USER_DESKTOP_DIR:-}" ]; then
        shortcut="${USER_DESKTOP_DIR}/${slug}.desktop"
        printf '%s\n' "$desktop_entry" > "$shortcut"
        chmod 755 "$shortcut"
        command -v gio >/dev/null 2>&1 && \
            gio set "$shortcut" "metadata::trusted" yes 2>/dev/null || true
    fi

    ok "Installiert: $title"
    INSTALLED=$((INSTALLED + 1))
done

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && \
    gtk-update-icon-cache -q -t -f "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true

echo ""
ok "Installation abgeschlossen: ${INSTALLED}/${#GAMES[@]} Spiele installiert."
echo "    Spiele-Ordner : ${INSTALL_DIR}"
echo "    App-Menü      : ${DESKTOP_DIR}"
[ -n "${USER_DESKTOP_DIR:-}" ] && [ -d "${USER_DESKTOP_DIR:-}" ] && \
    echo "    Desktop       : ${USER_DESKTOP_DIR}"

if [ "${#SKIPPED_ICON[@]}" -gt 0 ]; then
    echo ""
    info "Ohne eigenes Icon installiert (Fallback '${FALLBACK_ICON_NAME}' genutzt):"
    for t in "${SKIPPED_ICON[@]}"; do
        echo "    - $t"
    done
fi