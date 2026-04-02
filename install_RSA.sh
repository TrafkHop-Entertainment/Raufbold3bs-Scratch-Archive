#!/bin/bash

# Pfad als Variable definieren (Sauberer und leichter zu ändern)
TARGET_DIR="$HOME/.local/share/trafkhop-entertainment/raufbold3bs-scratch-archive"

# Verzeichnis erstellen
mkdir -p "$TARGET_DIR"

# In das Verzeichnis wechseln
cd "$TARGET_DIR" || { echo "Fehler: Verzeichnis konnte nicht betreten werden"; exit 1; }

# Die URLs der ZIP-Dateien
URLS=(
    "https://github.com/Trafkhop-Entertainment/Raufbold3bs-Scratch-Archive/raw/ab36d7bccd37365bfd900ac4b8264425446a31b3/RSA_Offline-Collection/RSA_Offline-Collection-1.zip"
    "https://github.com/Trafkhop-Entertainment/Raufbold3bs-Scratch-Archive/raw/ab36d7bccd37365bfd900ac4b8264425446a31b3/RSA_Offline-Collection/RSA_Offline-Collection-2.zip"
    "https://github.com/Trafkhop-Entertainment/Raufbold3bs-Scratch-Archive/raw/ab36d7bccd37365bfd900ac4b8264425446a31b3/RSA_Offline-Collection/RSA_Offline-Collection-3.zip"
)

echo "Starte Download und Entpacken in: $TARGET_DIR"

for url in "${URLS[@]}"; do
    echo "Verarbeite: $url"

    # Download mit -s (silent) aber -S (zeige Fehler) und -L (Folge Redirects)
    curl -SL "$url" -o temp.zip

    # Entpacken
    # Hinweis: -j löscht die Ordnerstruktur im ZIP.
    # Wenn die ZIPs eigene Unterordner haben, die du behalten willst, nimm das -j raus!
    unzip -o temp.zip

    # Temporäre Datei löschen
    rm temp.zip
done

echo "Fertig! Alle Dateien befinden sich in $TARGET_DIR"
