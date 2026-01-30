#!/usr/bin/env bash
set -euo pipefail

# Instala Android Studio vía Snap (Ubuntu/Debian con snapd).
# Requiere: snapd instalado y funcionando.

if ! command -v snap >/dev/null 2>&1; then
  echo "ERROR: No encuentro 'snap'. Instala snapd primero (Ubuntu/Debian):"
  echo "  sudo apt update && sudo apt install -y snapd"
  exit 1
fi

echo "Instalando Android Studio (Snap)..."
sudo snap install android-studio --classic

echo "Listo. Puedes lanzarlo con: android-studio"

