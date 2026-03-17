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
: "${GAME_BLOCKLIST:=}"

GAME_REASON=""
CURRENT_UID=$(id -u)

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

is_blocked_command() {
    local cmdline="$1"
    local matcher="$2"
    local cmdline_lc="${cmdline,,}"
    local matcher_lc="${matcher,,}"
    local raw trimmed entry_matcher entry_block entry_block_lc entry_matcher_lc
    local patterns=()
    local IFS=','

    [[ -z "$GAME_BLOCKLIST" ]] && return 1

    read -ra patterns <<<"$GAME_BLOCKLIST"

    for raw in "${patterns[@]}"; do
        raw=$(trim "$raw")
        [[ -z "$raw" ]] && continue

        if [[ "$raw" == *"::"* ]]; then
            entry_matcher=$(trim "${raw%%::*}")
            entry_block=$(trim "${raw#*::}")
        else
            entry_matcher=""
            entry_block="$raw"
        fi

        [[ -z "$entry_block" ]] && continue
        entry_block_lc="${entry_block,,}"

        if [[ -n "$entry_matcher" ]]; then
            entry_matcher_lc="${entry_matcher,,}"
            [[ "$matcher_lc" != "$entry_matcher_lc" ]] && continue
        fi

        if [[ "$cmdline_lc" == *"$entry_block_lc"* ]]; then
            return 0
        fi
    done

    return 1
}

process_matches() {
    local matcher="$1"
    local mode="args"
    local token="$matcher"
    local line pid comm args full full_lc token_lc first_arg exe_path exe_base

    case "$matcher" in
        cmd:*|name:*)
            mode="command"
            token="${matcher#*:}"
            ;;
        exe:*)
            mode="exe"
            token="${matcher#*:}"
            ;;
        args:*)
            token="${matcher#*:}"
            ;;
    esac

    token=$(trim "$token")
    [[ -z "$token" ]] && return 1
    token_lc="${token,,}"

    while read -r pid comm args; do
        [[ -z "$pid" ]] && continue
        full="$comm $args"
        full_lc="${full,,}"

        if [[ "$mode" == "command" ]]; then
            if [[ "${comm,,}" != "$token_lc" ]]; then
                if [[ -n "$args" ]]; then
                    first_arg=${args%% *}
                    first_arg=${first_arg##*/}
                    if [[ "${first_arg,,}" != "$token_lc" ]]; then
                        continue
                    fi
                else
                    continue
                fi
            fi
        elif [[ "$mode" == "exe" ]]; then
            exe_path=$(readlink "/proc/$pid/exe" 2>/dev/null || true)
            exe_match=false

            if [[ -n "$exe_path" ]]; then
                exe_base=${exe_path##*/}
                if [[ "${exe_base,,}" == "$token_lc" ]]; then
                    exe_match=true
                fi
            fi

            if [[ "$exe_match" == false ]]; then
                first_arg=${args%% *}
                first_arg=${first_arg##*/}
                if [[ -n "$first_arg" && "${first_arg,,}" == "$token_lc" ]]; then
                    exe_match=true
                fi
            fi

            [[ "$exe_match" == true ]] || continue
        else
            if [[ "$full_lc" != *"$token_lc"* ]]; then
                continue
            fi
        fi

        if ! is_blocked_command "$full" "$matcher"; then
            if [[ "$mode" == "command" ]]; then
                GAME_REASON="process command \"$comm\" matched \"$token\""
            elif [[ "$mode" == "exe" ]]; then
                GAME_REASON="binary \"$exe_base\" matched \"$token\""
            else
                GAME_REASON="process matched \"$token\""
            fi
            return 0
        fi
    done < <(ps -u "$CURRENT_UID" -o pid= -o comm= -o args=)

    return 1
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

get_device_rate() {
    local device output rate

    for device in $(get_devices); do
        if output=$(ratbagctl "$device" rate get 2>/dev/null); then
            rate=$(grep -Eo '[0-9]+' <<<"$output" | head -n1 || true)
            if [[ -n "$rate" ]]; then
                echo "$rate"
                return 0
            fi
        fi
    done

    return 1
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

is_gaming() {
    local raw_pattern trimmed
    local patterns=()
    local IFS=','

    GAME_REASON=""

    if steam_game_running; then
        return 0
    fi

    read -ra patterns <<<"$GAME_MATCHERS"

    for raw_pattern in "${patterns[@]}"; do
        trimmed=$(trim "$raw_pattern")
        [[ -z "$trimmed" ]] && continue

        if process_matches "$trimmed"; then
            return 0
        fi
    done

    return 1
}

if ! LAST_APPLIED_RATE=$(get_device_rate); then
    LAST_APPLIED_RATE=$(get_current_rate)
else
    echo "$LAST_APPLIED_RATE" > "$FILE_PATH"
fi

set_rate_all_devices "$MIN_RATE" "Startup default"
LAST_APPLIED_RATE="$MIN_RATE"

# -----------------------------
# Main loop
# -----------------------------
while true; do
    if is_gaming; then
        target_rate="$MAX_RATE"
        reason="${GAME_REASON:-Game process detected}"
    else
        target_rate="$MIN_RATE"
        reason="No game processes detected"
    fi

    if [[ "$LAST_APPLIED_RATE" != "$target_rate" ]]; then
        set_rate_all_devices "$target_rate" "$reason"
        LAST_APPLIED_RATE="$target_rate"
    fi

    sleep "$INTERVAL"
done
