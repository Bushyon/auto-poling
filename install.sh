#!/bin/bash

# Get the script's directory
script_dir=$(dirname "$(readlink -f "$0")")
env_file="$script_dir/.env"

if [[ -f "$env_file" ]]; then
    . "$env_file"
fi

: "${MIN_POLLING_RATE:=125}"
: "${MAX_POLLING_RATE:=500}"
: "${UPDATE_INTERVAL:=20}"
: "${SERVICE_NAME:=auto-poling}"

# Define the script and service paths
script_path="$script_dir/auto-poling.sh"
service_name="$SERVICE_NAME"

# Default values
min_polling_rate="$MIN_POLLING_RATE"
max_polling_rate="$MAX_POLLING_RATE"
update_interval="$UPDATE_INTERVAL"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --min) min_polling_rate="$2"; shift ;;
        --max) max_polling_rate="$2"; shift ;;
        --update) update_interval="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check if no parameters were provided
if [ "$#" -eq 0 ]; then
    echo "No parameters provided. Using default values."
    echo "Min polling rate: $min_polling_rate, Max polling rate: $max_polling_rate, Update interval: $update_interval seconds"
    echo "You can modify these values by using the --min, --max, and --update parameters."
fi

# Create the service file with custom parameters
service_content="[Unit]\nDescription=Polling Rate Control Script\nAfter=ratbagd.service\n\n[Service]\nExecStart=$script_path --min $min_polling_rate --max $max_polling_rate --update $update_interval\n\n[Install]\nWantedBy=default.target"

echo -e $service_content > ~/.config/systemd/user/$service_name.service

# Enable the service
systemctl --user enable $service_name.service

# Reload the system daemon
systemctl --user daemon-reload

# Start the service
systemctl --user start $service_name.service

# Show the status of the service
systemctl --user status $service_name.service
