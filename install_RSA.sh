#!/bin/bash

TARGET_DIR="$HOME/.local/share/trafkhop-entertainment/raufbold3bs-scratch-archive"
MENU_JSON_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/menu.json"

mkdir -p "$TARGET_DIR"

cd "$TARGET_DIR" || { echo "Error: Could not enter directory"; exit 1; }

# Direkte Liste der 15 HTML-Spiele
GAMES=(
    "RSA _ auto v2.html"
    "RSA _ Der Apfel und der Kürbis.html"
    "RSA _ Die 2 Cops.html"
    "RSA _ Die Abenteuer von Ritter Goffy und seinem schlauen Kollegen Blufi 5 The game.html"
    "RSA _ Flappy Pyley.html"
    "RSA _ grasi 1.4.3 (Costume overhaul 1) (basic jumping no hole).html"
    "RSA _ Gras-Zupf Simulator (EarlyAccess) v.0.64.html"
    "RSA _ Mayro rpg.html"
    "RSA _ Pyley Fang.html"
    "RSA _ Pyley Jump.html"
    "RSA _ Pyley Run 1.0.html"
    "RSA _ Pyley's Adventures.html"
    "RSA _ Pyley's Hunt.html"
    "RSA _ Retro Klavier.html"
    "RSA _ Sonnenpflicht.html"
)

BASE_URL="https://raw.githubusercontent.com/Trafkhop-Entertainment/Raufbold3bs-Scratch-Archive/main/html%20games"

echo "Starting download in: $TARGET_DIR"

for game in "${GAMES[@]}"; do
    # URL-Encoding für wget (Leerzeichen, Apostrophe, Umlaute anpassen)
    encoded_game="${game// /%20}"
    encoded_game="${encoded_game//\'/%27}"
    encoded_game="${encoded_game//ü/%C3%BC}"

    echo "Downloading: $game ..."
    # -O erzwingt, dass die Datei unter ihrem sauberen Originalnamen gespeichert wird
    if ! wget -q --show-progress -O "$game" "$BASE_URL/$encoded_game"; then
        echo "Error downloading $game"
    fi
done

echo "Download complete!"
echo ""

read -n 1 -p "Do you want to integrate RSA HTML games into the TrafkTux Rofi menu? (y/n): " response
echo ""

if [[ "$response" =~ ^[YyJj]$ ]]; then
    echo "» Integrating RSA HTML games into Rofi menu..."

    if ! command -v jq &>/dev/null; then
        echo "Notice: 'jq' is required to update menu.json. Please install it via your package manager."
        exit 0
    fi

    if [ ! -f "$MENU_JSON_FILE" ]; then
        mkdir -p "$(dirname "$MENU_JSON_FILE")"
        echo '{"1 System":{}, "2 Work":{}, "3 Utilities":{}, "4 Games":{}, "5 Multimedia":{}, "6 Settings":{}, "7 Social":{}}' > "$MENU_JSON_FILE"
    fi

    TMP_GAMES_JSON=$(mktemp)
    echo '{}' > "$TMP_GAMES_JSON"

    find "$TARGET_DIR" -type f -name "*.html" | while read -r html_path; do
        game_name=$(basename "$html_path" .html)
        game_name="${game_name//_/ }"
        game_name="${game_name//-/ }"

        jq --arg name "$game_name" --arg cmd "xdg-open \"$html_path\"" '. + {($name): $cmd}' "$TMP_GAMES_JSON" > "${TMP_GAMES_JSON}.tmp" && mv "${TMP_GAMES_JSON}.tmp" "$TMP_GAMES_JSON"
    done

    if [ -f "$TMP_GAMES_JSON" ] && [ "$(stat -c%s "$TMP_GAMES_JSON")" -gt 4 ]; then
        games_content=$(cat "$TMP_GAMES_JSON")

        jq --argjson new_games "$games_content" '
            if .["4 Games"] == null or (.["4 Games"] | type != "object") then .["4 Games"] = {} else . end
            | .["4 Games"]["RSA Collection"] = $new_games
        ' "$MENU_JSON_FILE" > "${MENU_JSON_FILE}.tmp" && mv "${MENU_JSON_FILE}.tmp" "$MENU_JSON_FILE"

        echo "» RSA Collection successfully added with $(jq 'length' "$TMP_GAMES_JSON") games to '4 Games/RSA Collection'!"
    else
        echo "» No HTML files found to add."
    fi

    rm -f "$TMP_GAMES_JSON"
else
    echo "» Rofi integration skipped."
fi

echo "Done!"
