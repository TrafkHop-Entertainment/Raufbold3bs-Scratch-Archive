#!/bin/bash

TARGET_DIR="$HOME/.local/share/trafkhop-entertainment/raufbold3bs-scratch-archive"

mkdir -p "$TARGET_DIR"

cd "$TARGET_DIR" || { echo "ERROR: $TARGET_DIR could not be entered..."; exit 1; }

URLS=(
    "https://github.com/Trafkhop-Entertainment/Raufbold3bs-Scratch-Archive/raw/ab36d7bccd37365bfd900ac4b8264425446a31b3/RSA_Offline-Collection/RSA_Offline-Collection-1.zip"
    "https://github.com/Trafkhop-Entertainment/Raufbold3bs-Scratch-Archive/raw/ab36d7bccd37365bfd900ac4b8264425446a31b3/RSA_Offline-Collection/RSA_Offline-Collection-2.zip"
    "https://github.com/Trafkhop-Entertainment/Raufbold3bs-Scratch-Archive/raw/ab36d7bccd37365bfd900ac4b8264425446a31b3/RSA_Offline-Collection/RSA_Offline-Collection-3.zip"
)

echo "Started download and exctacting files under: $TARGET_DIR"

for url in "${URLS[@]}"; do
    echo "Progress: $url"

    curl -SL "$url" -o temp.zip

    unzip -o temp.zip

    rm temp.zip
done

echo "Successfully installed the RSA Offline Collection under: $TARGET_DIR"
