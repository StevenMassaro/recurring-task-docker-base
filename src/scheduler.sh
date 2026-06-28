#!/bin/sh
echo "$(date) - start scheduler"

# Convert a duration like "1d" or "3600" into seconds
duration_to_seconds() {
    case "$1" in
        *d) echo $(( ${1%d} * 86400 )) ;;
        *h) echo $(( ${1%h} * 3600 )) ;;
        *m) echo $(( ${1%m} * 60 )) ;;
        *s) echo $(( ${1%s} )) ;;
        *) echo "$1" ;; # assume seconds if no suffix
    esac
}

DELAY="${DELAY:-1d}"
ADJUST_FOR_RUNTIME="${ADJUST_FOR_RUNTIME:-true}"
CHECK_LAST_RUNTIME="${CHECK_LAST_RUNTIME:-false}"
LAST_RUNTIME_FILE="${LAST_RUNTIME_FILE:-/tmp/last_runtime}"

while :; do
    echo "$(date) - execute"

    # If CHECK_LAST_RUNTIME is enabled, check when we last ran and wait if needed
    if [ "$CHECK_LAST_RUNTIME" = "true" ]; then
        delay_seconds=$(duration_to_seconds "$DELAY")
        if [ -f "$LAST_RUNTIME_FILE" ]; then
            last_runtime=$(cat "$LAST_RUNTIME_FILE")
            current_time=$(date +%s)
            time_since_last_runtime=$(( current_time - last_runtime ))

            if [ "$time_since_last_runtime" -lt "$delay_seconds" ]; then
                sleep_time=$(( delay_seconds - time_since_last_runtime ))
                echo "$(date) - Last runtime was $time_since_last_runtime seconds ago, sleeping for $sleep_time seconds to reach $DELAY interval"
                sleep "$sleep_time"
            else
                echo "$(date) - Last runtime was $time_since_last_runtime seconds ago (>= $DELAY), not sleeping"
            fi
        else
            echo "$(date) - No last runtime file found, not sleeping"
        fi
    fi

    start_time=$(date +%s)
    ./execute.sh
    end_time=$(date +%s)

    # Update the last runtime file
    echo "$end_time" > "$LAST_RUNTIME_FILE"

    if [ "$ADJUST_FOR_RUNTIME" = "true" ]; then
        runtime=$(( end_time - start_time ))
        delay_seconds=$(duration_to_seconds "$DELAY")
        sleep_time=$(( delay_seconds - runtime ))
        if [ "$sleep_time" -lt 0 ]; then
            echo "$(date) - Execution took longer than the delay ($runtime > $delay_seconds), skipping sleep"
            sleep_time=0
        fi
    else
        sleep_time=$delay_seconds
    fi

    echo "$(date) - sleeping for $sleep_time seconds"
    sleep "$sleep_time"
done
