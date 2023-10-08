#!/bin/bash

# Define the service name
service_name="AutoPoling"

# Stop and disable the service
systemctl --user stop $service_name.service
systemctl --user disable $service_name.service

# Remove the service file
rm ~/.config/systemd/user/$service_name.service

# Reload the system daemon
systemctl --user daemon-reload
