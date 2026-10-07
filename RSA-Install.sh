#!/bin/bash

TARGET_DIR="$HOME/.local/share/TrafkHop-Entertainment/Raufbold3bs-Scratch-Archive"

mkdir -p "$TARGET_DIR"

cd "$TARGET_DIR" || { echo "Error: Could not enter directory"; exit 1; }

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
    if ! wget -q --show-progress -O "$game" "$BASE_URL/$encoded_game"; then
        echo "Error downloading $game"
    fi
done

echo "Download complete!"
echo ""

echo "Done!"
