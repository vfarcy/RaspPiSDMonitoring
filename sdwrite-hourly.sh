#!/bin/bash
set -e

# Chemin vers la bibliothèque
LIB_PATH="$(dirname "$0")/lib.sh"

if [ ! -f "$LIB_PATH" ]; then
    echo "Erreur : bibliothèque $LIB_PATH introuvable"
    exit 1
fi

source "$LIB_PATH"

# Durée de mesure (en secondes)
DURATION="$1"

if [ -z "$DURATION" ]; then
    echo "Usage: $0 <durée_en_secondes>"
    exit 1
fi

# Horodatage FR
TIMESTAMP=$(LC_TIME=fr_FR.UTF-8 date "+%A %d %B %Y %H:%M:%S")

###############################################
# Envoi de l'horodatage seul
###############################################
send_telegram_message "Horodatage : $TIMESTAMP"

###############################################
# Mesure brute
###############################################
start=$(awk '{print $7}' "$STAT_FILE")
sleep "$DURATION"
end=$(awk '{print $7}' "$STAT_FILE")

sectors_measured=$((end - start))
sectors_per_min=$(echo "scale=2; $sectors_measured / $DURATION * 60" | bc)

###############################################
# Envoi des résultats
###############################################
send_telegram_message "Mesure SD : durée $DURATION s"

affiche_resultats() {
    local label="$1"
    local sectors="$2"

    local bytes=$((sectors * 512))
    local ko=$(echo "scale=2; $bytes / 1024" | bc)
    local mo=$(echo "scale=2; $bytes / 1024 / 1024" | bc)
    local go=$(echo "scale=4; $bytes / 1024 / 1024 / 1024" | bc)

    send_telegram_message "$label\nSecteurs : $sectors\nKo : $ko\nMo : $mo\nGo : $go"
}

affiche_resultats "Mesure brute" "$sectors_measured"
affiche_resultats "Mesure ramenée à 1 minute" "$(printf "%.0f" $sectors_per_min)"

###############################################
# Mise à jour de l'historique 24h (en RAM)
###############################################
current_hour=$(date "+%H")

# Création du fichier si absent
if [ ! -f "$HIST_FILE" ]; then
    # Ensure the directory exists
    mkdir -p "$(dirname "$HIST_FILE")"
    for h in $(seq -w 0 23); do
        echo "$h 0" >> "$HIST_FILE"
    done
fi

# Mise à jour de l'heure courante
tmpfile=$(mktemp)
awk -v h="$current_hour" -v v="$sectors_per_min" '
{
    if ($1 == h) print h, v;
    else print $0;
}' "$HIST_FILE" > "$tmpfile"

mv "$tmpfile" "$HIST_FILE"

###############################################
# Graphique instantané (barres)
###############################################
PLOT_DATA="/dev/shm/sdwrite-data.txt"
PLOT_IMG="/dev/shm/sdwrite-plot.png"

echo -e "Brut $sectors_measured\nPar_minute $sectors_per_min" > "$PLOT_DATA"

gnuplot <<EOF
set terminal pngcairo size 900,450 enhanced font 'Arial,12'
set output "$PLOT_IMG"

set title "Écritures SD" font ",14"
set style data histograms
set style fill solid 1.0 border -1
set boxwidth 0.6

set grid ytics
set ylabel "Secteurs écrits"

stats "$PLOT_DATA" using 2 nooutput

safe_limit = 50
alert_limit = 200

maxval = STATS_max
if (maxval < alert_limit) { maxval = alert_limit }
set yrange [0:maxval*1.20]

set arrow from graph 0, first safe_limit to graph 1, first safe_limit nohead lc rgb "green" lw 2
set arrow from graph 0, first alert_limit to graph 1, first alert_limit nohead lc rgb "red" lw 2

set xtics rotate by -20

set label 1 sprintf("%d", $sectors_measured) \
    at 1, $sectors_measured + ($sectors_measured * 0.05) center tc rgb "black"

set label 2 sprintf("%d", $sectors_per_min) \
    at 2, $sectors_per_min + ($sectors_per_min * 0.05) center tc rgb "black"

plot "$PLOT_DATA" using 2:xtic(1) title "Secteurs"
EOF

send_telegram_photo "$PLOT_IMG" "Graphique SD"

rm -f "$PLOT_DATA" "$PLOT_IMG"
