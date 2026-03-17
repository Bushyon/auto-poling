#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")
env_file="$script_dir/.env"

if [[ -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    . "$env_file"
fi

: "${SERVICE_NAME:=auto-poling}"

# Define the service name
service_name="$SERVICE_NAME"

# Stop and disable the service
systemctl --user stop $service_name.service
systemctl --user disable $service_name.service

# Remove the service file
rm ~/.config/systemd/user/$service_name.service

# Reload the system daemon
systemctl --user daemon-reload
