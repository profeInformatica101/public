#!/usr/bin/env bash
# install-systemd-manager-tui.sh
# Script para descargar, compilar e instalar systemd-manager-tui desde GitHub.
# Funciona en Debian/Ubuntu, Fedora, Arch (y derivadas).
#
# Uso:
#   chmod +x install-systemd-manager-tui.sh
#   ./install-systemd-manager-tui.sh
#
# El script:
#  - detecta la distro
#  - instala dependencias básicas (git, build tools, rust)
#  - clona el repo en /tmp y muestra el README/último commit
#  - compila con cargo --release
#  - instala el binario en /usr/local/bin
#  - ofrece instrucciones de uso y desinstalación

set -euo pipefail
IFS=$'\n\t'

REPO="https://github.com/matheus-git/systemd-manager-tui.git"
TMPDIR="$(mktemp -d)"
BIN_NAME="systemd-manager-tui"
INSTALL_DIR="/usr/local/bin"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "== Instalador: systemd-manager-tui =="
echo

# Detectar gestor de paquetes
PKG_INSTALL=""
PKG_UPDATE=""
DIST=""
if command -v apt-get >/dev/null 2>&1; then
  DIST="debian"
  PKG_INSTALL="sudo apt-get install -y"
  PKG_UPDATE="sudo apt-get update"
elif command -v dnf >/dev/null 2>&1; then
  DIST="fedora"
  PKG_INSTALL="sudo dnf install -y"
  PKG_UPDATE="sudo dnf makecache"
elif command -v pacman >/dev/null 2>&1; then
  DIST="arch"
  PKG_INSTALL="sudo pacman -S --needed --noconfirm"
  PKG_UPDATE="sudo pacman -Sy"
else
  echo "No se ha detectado apt, dnf ni pacman. Instala manualmente: git, curl, build-essential/base-devel, pkg-config, libsystemd-dev/libsystemd-devel y rustup."
  DIST="unknown"
fi

echo "Distribución detectada: $DIST"
echo

# Actualizar índices si es posible
if [ -n "$PKG_UPDATE" ]; then
  echo "Actualizando índices de paquetes..."
  $PKG_UPDATE
fi

# Instalar dependencias según distro
echo "Instalando dependencias necesarias (si faltan)..."
case "$DIST" in
  debian)
    $PKG_INSTALL curl git build-essential pkg-config libsystemd-dev libdbus-1-dev
    ;;
  fedora)
    $PKG_INSTALL curl git make gcc pkgconfig systemd-devel dbus-devel
    ;;
  arch)
    $PKG_INSTALL curl git base-devel pkgconf systemd
    ;;
  *)
    echo "No se ha podido automatizar la instalación de dependencias para tu distro."
    echo "Asegúrate de tener: git, curl, compilador (gcc/make), pkg-config, librerías de systemd/libdbus y Rust toolchain (rustup)."
    ;;
esac

# Instalar rustup si no existe
if ! command -v cargo >/dev/null 2>&1; then
  echo
  echo "Rust (cargo) no encontrado. Instalando rustup (toolchain estable) para el usuario..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
  echo "Rust instalado. Versión: $(rustc --version || true)"
else
  echo "cargo ya instalado: $(cargo --version)"
fi

# Clonar el repo
echo
echo "Clonando $REPO en $TMPDIR..."
git clone --depth 1 "$REPO" "$TMPDIR/$BIN_NAME"
cd "$TMPDIR/$BIN_NAME"

# Mostrar últimos commits / README corto
echo
echo "Último commit en el repo:"
git --no-pager log -1 --pretty=format:"%h - %an (%ad) - %s"
echo
echo "Fragmento del README (primeras 30 líneas):"
echo "--------------------------------------------------"
head -n 30 README.md || true
echo "--------------------------------------------------"
echo

# (Opcional) pedir confirmación antes de compilar
read -r -p "¿Continuar con la compilación e instalación? [Y/n] " ANSWER
ANSWER=${ANSWER:-Y}
if [[ ! $ANSWER =~ ^[Yy] ]]; then
  echo "Cancelado por el usuario."
  exit 0
fi

# Compilar en release
echo
echo "Compilando en modo release (cargo build --release)..."
# Asegurarse de usar toolchain estable y evitar sorpresas
rustup default stable >/dev/null 2>&1 || true
cargo build --release --locked

# Verificar binario
BUILT_BIN="target/release/$BIN_NAME"
if [ ! -f "$BUILT_BIN" ]; then
  echo "Error: binario no encontrado en $BUILT_BIN"
  exit 1
fi

# Instalar binario (requiere sudo)
echo
echo "Instalando $BIN_NAME en $INSTALL_DIR (se pedirá contraseña sudo si es necesario)..."
sudo install -m 0755 "$BUILT_BIN" "$INSTALL_DIR/$BIN_NAME"

echo
echo "Instalación completada. Ruta: $INSTALL_DIR/$BIN_NAME"
echo

# Consejos de uso y seguridad
cat <<'EOF'
== Recomendaciones de uso y seguridad ==

1) Revisa el repo antes de usar en producción:
   - lee el README.md y los archivos fuente si te preocupa la seguridad.
   - puedes ejecutar: git log --oneline y revisar los cambios.

2) Ejecuta primero en modo lectura/consulta:
   - usa: systemd-manager-tui --help
   - o: systemd-manager-tui (verá servicios, sin cambios si no ejecutas acciones)

3) Gestión de permisos:
   - Para gestionar servicios de sistema: necesitarás permisos de root (p. ej. sudo).
     Ejemplo: sudo systemd-manager-tui
   - Para gestionar servicios de usuario (sin sudo): usa systemctl --user y, si la herramienta lo soporta, ejecuta sin sudo.

4) Para desinstalar:
   - sudo rm -f /usr/local/bin/systemd-manager-tui
   - (y opcionalmente borra el directorio de compilación en /tmp si queda algo)

5) Actualizaciones:
   - Para actualizar: vuelve a ejecutar este script (o git pull en el repo y recompila).
   - Si quieres usar paquetes del sistema (AUR, .deb o .rpm), prefierelos si existen para tu distro.

EOF

echo
echo "Prueba ahora con: systemd-manager-tui --help"
echo "Si quieres, puedo darte la variante para instalar desde AUR (.pkgbuild) o un .deb/.rpm si lo prefieres."
