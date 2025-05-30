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

while :; do
    echo "$(date) - execute"

    start_time=$(date +%s)
    ./execute.sh
    end_time=$(date +%s)

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
