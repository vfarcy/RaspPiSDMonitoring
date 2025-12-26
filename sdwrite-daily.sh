#!/bin/bash
set -e

# Chemin vers la bibliothèque
LIB_PATH="$(dirname "$0")/lib.sh"

if [ ! -f "$LIB_PATH" ]; then
    echo "Erreur : bibliothèque $LIB_PATH introuvable"
    exit 1
fi

source "$LIB_PATH"

PLOT_IMG=$(mktemp)

gnuplot <<EOF
set terminal pngcairo size 1000,450 enhanced font 'Arial,12'
set output "$PLOT_IMG"

set title "Activité d'écriture SD - Historique 24h" font ",14"
set xlabel "Heure"
set ylabel "Secteurs/minute"
set grid ytics

safe_limit = 50
alert_limit = 200

stats "$HIST_FILE" using 2 nooutput
maxval = STATS_max
if (maxval < alert_limit) { maxval = alert_limit }
set yrange [0:maxval*1.20]

set arrow from graph 0, first safe_limit to graph 1, first safe_limit nohead lc rgb "green" lw 2
set arrow from graph 0, first alert_limit to graph 1, first alert_limit nohead lc rgb "red" lw 2

plot "$HIST_FILE" using 2:xtic(1) with linespoints lw 2 lc rgb "blue" title "Débit/min"
EOF

send_telegram_photo "$PLOT_IMG" "Historique 24h"

rm -f "$PLOT_IMG"




