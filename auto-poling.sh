#!/bin/bash

# Default values
min_polling_rate=125
max_polling_rate=500
update_interval=20
devices=$(ratbagctl list | cut -d":" -f1)
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

echo "Running with min polling rate: $min_polling_rate, max polling rate: $max_polling_rate, and update interval: $update_interval seconds."

while true
do
    # Check if the "ratbagctl" command is available
    if ! command -v ratbagctl &> /dev/null
    then
        echo "The 'ratbagctl' command was not found. Please make sure the program is installed."
        exit 1
    fi

    # Define the file path in the /tmp directory
    file_path="/tmp/polling_rate.txt"

    # Check if the control file exists
    if [ -f $file_path ]; then
        # Read the polling rate from the file
        rate=$(cat $file_path)

        # Validate if the rate is a number
        if ! [[ "$rate" =~ ^[0-9]+$ ]]; then
            echo "Invalid polling rate found in file. Resetting to default."
            rate=$min_polling_rate
        fi
    else
        rate=$min_polling_rate
    fi

    if pgrep -a -f steam | grep reaper > /dev/null; then
        if [ $rate -ne $max_polling_rate ]; then
            for device in $devices;do ratbagctl $device rate set $max_polling_rate;done
            echo $max_polling_rate > $file_path
        fi
    else
        if [ $rate -ne $min_polling_rate ]; then
            for device in $devices;do ratbagctl $device rate set $min_polling_rate;done
            echo $min_polling_rate > $file_path
        fi
    fi

    sleep $update_interval
done
