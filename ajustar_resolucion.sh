#!/usr/bin/env bash

# Obtiene resolución actual del monitor físico (en el sistema host, si se comparte)
# o fija una resolución manual si no se puede detectar automáticamente.
RESOLUCION="1920x1080"

# Cambia la resolución con xrandr
xrandr --output Virtual1 --mode $RESOLUCION || xrandr --output VGA-0 --mode $RESOLUCION || xrandr --output HDMI-0 --mode $RESOLUCION

echo "Resolución ajustada a $RESOLUCION"
