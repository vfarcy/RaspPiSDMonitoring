#!/bin/bash

# Source the configuration file
CONFIG_FILE="$(dirname "$0")/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Erreur : fichier de configuration $CONFIG_FILE introuvable."
    echo "Veuillez copier config.sh.example vers config.sh et le modifier."
    exit 1
fi

# Check for deprecated config file
if [ -f /etc/default/sdwrite-kernelmonitor ]; then
    echo "Attention : le fichier de configuration /etc/default/sdwrite-kernelmonitor est obsolète."
    echo "Veuillez déplacer vos informations d'identification vers $CONFIG_FILE."
fi

# Check if BOT_TOKEN and CHAT_ID are set
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "Erreur : BOT_TOKEN ou CHAT_ID ne sont pas définis dans $CONFIG_FILE."
    exit 1
fi

send_telegram_message() {
    local msg="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
         -d chat_id="${CHAT_ID}" \
         -d text="$msg" > /dev/null
}

send_telegram_photo() {
    local photo_path="$1"
    local caption="$2"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto" \
         -F chat_id="${CHAT_ID}" \
         -F photo=@"$photo_path" \
         -F caption="$caption" > /dev/null
}
