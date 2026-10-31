#!/bin/bash
cd "$(dirname "$0")"

echo "========================================================"
echo " Instagram Non-Followers & Live Verifier App (macOS v9)"
echo "========================================================"

if [ ! -f "index.html" ]; then
    echo " [!] ERROR: index.html was not found in this folder!"
    read -p "Press ENTER to close..."
    exit 1
fi

if command -v python3 >/dev/null 2>&1; then
    python3 app_mac.py
elif command -v python >/dev/null 2>&1; then
    python app_mac.py
else
    echo " [!] Python 3 is required for the local background verifier on macOS."
    echo " Opening index.html in standard Browser Mode instead..."
    open "index.html"
fi
