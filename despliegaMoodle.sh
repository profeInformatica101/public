#!/usr/bin/env bash
# Script para desplegar Moodle con docker-compose
# Autor: profeInformatica101
# Uso:
#   chmod +x despliegaMoodle.sh
#   ./despliegaMoodle.sh

set -euo pipefail

# --- COLORES ---
GREEN="\e[32m"; RED="\e[31m"; NC="\e[0m"
info(){ echo -e "${GREEN}[INFO]${NC} $*"; }
error(){ echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# --- ACTUALIZAR E INSTALAR DEPENDENCIAS (Debian/Ubuntu) ---
if command -v apt-get >/dev/null 2>&1; then
  info "Actualizando el sistema..."
  sudo apt-get update -y
  info "Instalando dependencias necesarias..."
  sudo apt-get install -y curl wget gnupg lsb-release xdg-utils || true
fi

# --- DOCKER ---
if ! command -v docker >/dev/null 2>&1; then
  info "Docker no encontrado. Instalando..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER" || true
  info "Docker instalado (puede requerir re-login para usar sin sudo)."
else
  info "Docker ya está instalado."
fi

# Inicia y habilita Docker si hay systemd
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now docker || true
fi

# --- DOCKER COMPOSE (plugin o standalone) ---
if docker compose version >/dev/null 2>&1; then
  DC="docker compose"
  info "Usando 'docker compose' (plugin)."
else
  if ! command -v docker-compose >/dev/null 2>&1; then
    info "Instalando docker-compose standalone..."
    OS="$(uname -s)"
    ARCH="$(uname -m)"
    case "$ARCH" in
      x86_64) ARCH="x86_64" ;;
      aarch64|arm64) ARCH="aarch64" ;;
      armv7l) ARCH="armv7" ;;
    esac
    sudo curl -fsSL "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-${OS}-${ARCH}" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  fi
  DC="docker-compose"
  info "Usando 'docker-compose' (standalone)."
fi

# --- DESCARGAR docker-compose.yml ---
WORKDIR="$HOME/moodle-docker"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

COMPOSE_URL="https://raw.githubusercontent.com/profeInformatica101/docker/refs/heads/main/ejemplos/moodle/docker-compose.yml"
info "Descargando docker-compose.yml de Moodle..."
wget -qO docker-compose.yml "$COMPOSE_URL"

# --- DETECTAR PUERTO HOST PARA MOODLE (por defecto 8080) ---
detect_port(){
  # Soporta líneas tipo: - "8080:8080" o - 8080:8080
  local p
  p="$(grep -E '^\s*-\s*"?[0-9]+:8080"?\s*$' docker-compose.yml | head -n1 | sed -E 's/[^0-9]*([0-9]+):8080.*/\1/')"
  [[ -n "${p:-}" ]] && echo "$p" || echo "8080"
}
PORT="$(detect_port)"
info "Puerto HTTP host detectado: $PORT"

# --- ARRANCAR SOLO MARIADB Y ESPERAR A QUE ESTÉ LISTA ---
info "Arrancando MariaDB..."
$DC pull mariadb
$DC up -d mariadb

info "Esperando a que MariaDB acepte conexiones..."
# Intenta con mysqladmin ping desde el propio servicio
for i in {1..60}; do
  if $DC exec -T mariadb bash -lc 'mysqladmin ping -hmariadb -umoodle -pmoodle_password --silent' >/dev/null 2>&1; then
    info "MariaDB está listo."
    break
  fi
  sleep 2
  if [ "$i" -eq 60 ]; then
    $DC logs --tail=150 mariadb || true
    error "MariaDB no respondió a tiempo. Revisa credenciales o recursos."
  fi
done

# --- ARRANCAR MOODLE ---
info "Arrancando Moodle..."
$DC pull moodle
$DC up -d moodle

# --- ESPERAR A QUE ESCUCHE EL PUERTO ---
info "Esperando a que Moodle escuche en :$PORT ..."
for i in {1..30}; do
  if ss -ltn 2>/dev/null | grep -q ":${PORT} "; then
    break
  fi
  sleep 2
done

# Mostrar estado
$DC ps || true

# --- FIREWALL (opcional con UFW) ---
if command -v ufw >/dev/null 2>&1; then
  if sudo ufw status | grep -q "Status: active"; then
    info "Abriendo puerto $PORT/tcp en UFW..."
    sudo ufw allow "${PORT}/tcp" || true
  fi
fi

# --- ABRIR NAVEGADOR O MOSTRAR URL ---
URL="http://localhost:${PORT}"
if ss -ltn 2>/dev/null | grep -q ":${PORT} "; then
  if command -v xdg-open >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    info "Abriendo navegador en ${URL} ..."
    xdg-open "$URL" >/dev/null 2>&1 || info "No se pudo abrir automáticamente. Accede a: $URL"
  else
    HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
    [[ -z "${HOST_IP}" ]] && HOST_IP="127.0.0.1"
    info "Entorno sin GUI. Accede desde tu navegador a:"
    echo "  -> http://${HOST_IP}:${PORT}"
  fi
  info "🚀 Moodle desplegado correctamente."
else
  info "El puerto aún no está escuchando. Logs para diagnóstico:"
  $DC logs --tail=150 moodle || true
  $DC logs --tail=150 mariadb || true
  error "Moodle no está escuchando en :$PORT. Revisa los logs anteriores."
fi
