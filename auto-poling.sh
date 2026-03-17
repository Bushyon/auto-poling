#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ENV_FILE="${SCRIPT_DIR}/.env"

if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    . "$ENV_FILE"
fi

: "${MIN_POLLING_RATE:=125}"
: "${MAX_POLLING_RATE:=500}"
: "${UPDATE_INTERVAL:=20}"
: "${POLLING_FILE_PATH:="$HOME/.config/polling_rate.txt"}"
: "${GAME_MATCHERS:="steam_appid,reaper,gamescope"}"
: "${MINECRAFT_MATCHERS:="minecraft-launcher,.minecraft,net.minecraft.client.main.Main,PrismLauncher,MultiMC,ATLauncher"}"

GAME_REASON=""
CURRENT_UID=$(id -u)

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# -----------------------------
# Defaults
# -----------------------------
MIN_RATE="$MIN_POLLING_RATE"
MAX_RATE="$MAX_POLLING_RATE"
INTERVAL="$UPDATE_INTERVAL"
FILE_PATH="$POLLING_FILE_PATH"

# -----------------------------
# Argument parsing
# -----------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --min) MIN_RATE="$2"; shift ;;
        --max) MAX_RATE="$2"; shift ;;
        --update) INTERVAL="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "Min: $MIN_RATE | Max: $MAX_RATE | Interval: ${INTERVAL}s"

# -----------------------------
# Pre-flight checks
# -----------------------------
if ! command -v ratbagctl >/dev/null 2>&1; then
    echo "Error: ratbagctl not found."
    exit 1
fi

mkdir -p "$(dirname "$FILE_PATH")"

# Initialize file if missing
if [[ ! -f "$FILE_PATH" ]]; then
    echo "$MIN_RATE" > "$FILE_PATH"
fi

# -----------------------------
# Helper functions
# -----------------------------
get_devices() {
    ratbagctl list | cut -d":" -f1
}

get_current_rate() {
    local rate
    rate=$(cat "$FILE_PATH" 2>/dev/null || echo "$MIN_RATE")

    if [[ "$rate" =~ ^[0-9]+$ ]]; then
        echo "$rate"
    else
        echo "$MIN_RATE"
    fi
}

set_rate_all_devices() {
    local target_rate="$1"
    local reason="${2:-}"
    local devices

    devices=$(get_devices)

    for device in $devices; do
        ratbagctl "$device" rate set "$target_rate" || \
            echo "Warning: failed to set rate for $device"
    done

    echo "$target_rate" > "$FILE_PATH"
    if [[ -n "$reason" ]]; then
        echo "Polling rate set to $target_rate ($reason)"
    else
        echo "Polling rate set to $target_rate"
    fi
}

steam_game_running() {
    local pid env_file entry steam_app_id steam_game_id env_dump

    while IFS= read -r pid; do
        env_file="/proc/$pid/environ"
        [[ -r "$env_file" ]] || continue

        steam_app_id=""
        steam_game_id=""

        env_dump="$(
            set +e
            set +o pipefail
            cat "$env_file" 2>/dev/null | tr '\0' '\n'
        )"
        [[ -n "$env_dump" ]] || continue

        while IFS= read -r entry; do
            case "$entry" in
                SteamAppId=*) steam_app_id=${entry#*=} ;;
                SteamGameId=*) steam_game_id=${entry#*=} ;;
            esac
        done <<<"$env_dump"

        if [[ -n "$steam_game_id" && "$steam_game_id" != "0" ]]; then
            GAME_REASON="Steam GameID $steam_game_id process detected (pid $pid)"
            return 0
        fi

        if [[ -z "$steam_game_id" && -n "$steam_app_id" && "$steam_app_id" != "0" ]]; then
            GAME_REASON="Steam AppId $steam_app_id process detected (pid $pid)"
            return 0
        fi
    done < <(pgrep -u "$CURRENT_UID" || true)

    return 1
}

minecraft_running() {
    local raw_pattern trimmed
    local patterns=()
    local IFS=','

    read -ra patterns <<<"$MINECRAFT_MATCHERS"

    for raw_pattern in "${patterns[@]}"; do
        trimmed=$(trim "$raw_pattern")
        [[ -z "$trimmed" ]] && continue

        if pgrep -a -u "$CURRENT_UID" -f "$trimmed" >/dev/null 2>&1; then
            GAME_REASON="Minecraft process matched \"$trimmed\""
            return 0
        fi
    done

    return 1
}

is_gaming() {
    local raw_pattern trimmed
    local patterns=()
    local IFS=','

    GAME_REASON=""

    if steam_game_running; then
        return 0
    fi

    if minecraft_running; then
        return 0
    fi

    read -ra patterns <<<"$GAME_MATCHERS"

    for raw_pattern in "${patterns[@]}"; do
        trimmed=$(trim "$raw_pattern")
        [[ -z "$trimmed" ]] && continue

        if pgrep -a -u "$CURRENT_UID" -f "$trimmed" >/dev/null 2>&1; then
            GAME_REASON="process matched \"$trimmed\""
            return 0
        fi
    done

    return 1
}

# -----------------------------
# Main loop
# -----------------------------
while true; do
    current_rate=$(get_current_rate)

    if is_gaming; then
        target_rate="$MAX_RATE"
        reason="${GAME_REASON:-Game process detected}"
    else
        target_rate="$MIN_RATE"
        reason="No game processes detected"
    fi

    if [[ "$current_rate" != "$target_rate" ]]; then
        set_rate_all_devices "$target_rate" "$reason"
    fi

    sleep "$INTERVAL"
done
