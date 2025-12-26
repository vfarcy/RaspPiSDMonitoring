# Raspberry Pi SD Card Write Monitoring

## Context
This project is used to monitor the write activity of an SD card on a Raspberry Pi that is used for ADSB (Automatic Dependent Surveillance-Broadcast) reception.

ADSB is a surveillance technology in which an aircraft determines its position via satellite navigation and periodically broadcasts it, enabling it to be tracked.

The Raspberry Pi is used to receive these ADSB signals and feed them to various online services like ADSB-Exchange, FlightRadar24, and FlightAware. This continuous data feeding can cause significant write activity on the SD card, which can lead to premature wear and failure. This project helps to monitor this activity.

It consists of two scripts:
- `sdwrite-hourly.sh`: measures the write activity every hour.
- `sdwrite-daily.sh`: generates a 24-hour history graph every day.

The scripts send the results to a Telegram chat.

## Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/RaspPiSDMonitoring.git
    cd RaspPiSDMonitoring
    ```

2.  **Configure the scripts:**
    -   Copy the `config.sh.example` file to `config.sh`:
        ```bash
        cp config.sh.example config.sh
        ```
    -   Edit `config.sh` and fill in your Telegram bot token and chat ID.
    -   Make sure the `config.sh` file is not readable by others:
        ```bash
        chmod 600 config.sh
        ```

3.  **Set up the cron jobs:**
    -   Open the crontab editor:
        ```bash
        crontab -e
        ```
    -   Add the following lines:
        ```cron
        # Mesure horaire (toutes les heures pile)
        0 * * * * /path/to/your/RaspPiSDMonitoring/sdwrite-hourly.sh 3600

        # Graphique quotidien (à 3h du matin)
        0 3 * * * /path/to/your/RaspPiSDMonitoring/sdwrite-daily.sh
        ```

## Security

The `config.sh` file contains sensitive information (your Telegram bot token).
Make sure to set the correct permissions (`chmod 600 config.sh`) to prevent other users from reading it.

## Deprecated configuration file

The old configuration file `/etc/default/sdwrite-kernelmonitor` is deprecated.
Please move your credentials to the `config.sh` file.
The scripts will display a warning if the old configuration file is found.