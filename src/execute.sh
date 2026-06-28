#!/bin/sh
eval "$COMMAND"
ret=$?

# Healthchecks.io integration: ping based on COMMAND result, before AFTER_COMMAND
if [ -n "$HEALTHCHECKS_URL" ]; then
    HEALTHCHECKS_SUCCESS_URL="${HEALTHCHECKS_URL}"
    HEALTHCHECKS_FAIL_URL="${HEALTHCHECKS_URL}/fail"
    hc_ping() {
        local url="$1"
        curl -fsS --max-time 10 "$url" >/dev/null 2>&1 || true
    }
    if [ $ret -eq 0 ]; then
        hc_ping "$HEALTHCHECKS_SUCCESS_URL"
    else
        hc_ping "$HEALTHCHECKS_FAIL_URL"
    fi
fi

if [ -n "$AFTER_COMMAND" ]
then
    if [ $ret -ne 0 ];
    then
        echo "$(date) - command failed with exit code $ret, not executing AFTER_COMMAND"
    else
        eval "$AFTER_COMMAND"
    fi
fi