#!/usr/bin/env bash
# Script para desplegar Moodle con docker-compose 
# Autor: profeInformatica101

set -euo pipefail

GREEN="\e[32m"; RED="\e[31m"; NC="\e[0m"
info(){ echo -e "${GREEN}[INFO]${NC} $*"; }
error(){ echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# --- PRERREQUISITOS ---
if command -v apt-get >/dev/null 2>&1; then
  info "Actualizando paquetes..."
  sudo apt-get update -y
  sudo apt-get install -y curl wget gnupg lsb-release xdg-utils || true
fi

# --- DOCKER ---
if ! command -v docker >/dev/null 2>&1; then
  info "Instalando Docker..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER" || true
fi
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now docker || true
fi

# --- DOCKER-COMPOSE ---
if ! command -v docker-compose >/dev/null 2>&1; then
  info "Instalando docker-compose..."
  OS="$(uname -s)"
  ARCH="$(uname -m)"
  sudo curl -fsSL \
    "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-${OS}-${ARCH}" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

DC="docker-compose"

# --- RUTA DE TRABAJO ---
WORKDIR="$HOME/moodle-docker"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
# --- DESCARGA DEL COMPOSE  ---
COMPOSE_URL="https://raw.githubusercontent.com/profeInformatica101/docker/v2/ejemplos/moodle/docker-compose.yml"
info "Descargando docker-compose.yml de $COMPOSE_URL ..."
wget -qO docker-compose.yml "$COMPOSE_URL" || error "No se pudo descargar docker-compose.yml"

# --- ARRANCAR ---
info "Levantando servicios Moodle + MariaDB ..."
$DC pull
$DC up -d

# --- PUERTO ---
PORT="$(grep -E '^\s*-\s*"?[0-9]+:8080"?\s*$' docker-compose.yml | head -n1 | sed -E 's/[^0-9]*([0-9]+):8080.*/\1/')"
[ -z "$PORT" ] && PORT=8080
URL="http://localhost:${PORT}"

info "Esperando a que Moodle arranque (puede tardar 30s)..."
sleep 30

if command -v xdg-open >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
  info "Abriendo navegador en $URL ..."
  xdg-open "$URL" || info "Abre manualmente: $URL"
else
  info "Accede desde tu navegador a: $URL"
fi

info "🚀 Moodle desplegado correctamente desde rama v3."
