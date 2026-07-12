#!/bin/sh
# Function to prefix each line of input with a timestamp
prefix_with_date() {
    while read line; do
        echo "$(date) - $line"
    done
}

# Execute the main command and prefix its output with timestamps
eval "$COMMAND" 2>&1 | prefix_with_date
command_ret=${PIPESTATUS[0]}

# Healthchecks.io integration: ping based on COMMAND result, before AFTER_COMMAND
if [ -n "$HEALTHCHECKS_URL" ]; then
    HEALTHCHECKS_SUCCESS_URL="${HEALTHCHECKS_URL}"
    HEALTHCHECKS_FAIL_URL="${HEALTHCHECKS_URL}/fail"
    hc_ping() {
        local url="$1"
        curl -fsS --max-time 10 "$url" >/dev/null 2>&1 || true
    }
    if [ $command_ret -eq 0 ]; then
        hc_ping "$HEALTHCHECKS_SUCCESS_URL"
    else
        hc_ping "$HEALTHCHECKS_FAIL_URL"
    fi
fi

if [ -n "$AFTER_COMMAND" ]
then
    if [ $command_ret -ne 0 ];
    then
        echo "$(date) - command failed with exit code $command_ret, not executing AFTER_COMMAND"
        exit $command_ret
    else
        # Execute the after command and prefix its output with timestamps
        eval "$AFTER_COMMAND" 2>&1 | prefix_with_date
        # Exit with the after command's exit code
        exit ${PIPESTATUS[0]}
    fi
else
    # No AFTER_COMMAND, exit with command's exit code
    exit $command_ret
fi