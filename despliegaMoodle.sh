#!/bin/bash
# Script para desplegar Moodle con docker-compose
# Autor: profeInformatica101
# >chmod+x despliegaMoodle.sh
# >bash despliegaMoodle.sh

set -e

# --- COLORES ---
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m" # sin color

# --- FUNCIONES ---
function info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# --- ACTUALIZAR PAQUETES ---
info "Actualizando el sistema..."
sudo apt-get update -y

# --- INSTALAR DEPENDENCIAS ---
info "Instalando dependencias necesarias..."
sudo apt-get install -y curl wget gnupg lsb-release xdg-utils

# --- INSTALAR DOCKER ---
if ! command -v docker &> /dev/null; then
    info "Docker no encontrado. Instalando..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    info "Docker instalado. Es posible que necesites cerrar sesión para aplicar permisos."
else
    info "Docker ya está instalado."
fi

# --- INSTALAR DOCKER COMPOSE ---
if ! command -v docker-compose &> /dev/null; then
    info "Instalando docker-compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    info "docker-compose ya está instalado."
fi

# --- DESCARGAR docker-compose.yml ---
WORKDIR="$HOME/moodle-docker"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

info "Descargando docker-compose.yml de Moodle..."
wget -O docker-compose.yml https://raw.githubusercontent.com/profeInformatica101/docker/refs/heads/main/ejemplos/moodle/docker-compose.yml

# --- LEVANTAR CONTENEDORES ---
info "Levantando Moodle con docker-compose..."
docker-compose up -d

# --- ESPERAR INICIO ---
info "Esperando 20s a que los contenedores arranquen..."
sleep 20

# --- ABRIR NAVEGADOR ---
PORT=8080
info "Abriendo Moodle en el navegador (http://localhost:$PORT)..."
xdg-open "http://localhost:$PORT" || info "Abre manualmente http://localhost:$PORT"

info "🚀 Moodle desplegado correctamente."
