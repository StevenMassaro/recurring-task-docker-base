#!/bin/sh
RETRIES="${RETRIES:-0}"
RETRY_BACKOFF="${RETRY_BACKOFF:-0}"

# Healthchecks.io integration: ping based on each COMMAND attempt, before AFTER_COMMAND
if [ -n "$HEALTHCHECKS_URL" ]; then
    HEALTHCHECKS_SUCCESS_URL="${HEALTHCHECKS_URL}"
    hc_ping() {
        local url="$1"
        curl -fsS --max-time 10 "$url" >/dev/null 2>&1 || true
    }
fi

retry_count=0
retry_delay="$RETRY_BACKOFF"
while :
do
    eval "$COMMAND"
    ret=$?

    if [ -n "$HEALTHCHECKS_URL" ]; then
        hc_ping "$HEALTHCHECKS_SUCCESS_URL/$ret"
    fi

    if [ "$ret" -eq 0 ] || [ "$retry_count" -ge "$RETRIES" ]; then
        break
    fi

    retry_count=$((retry_count + 1))
    echo "$(date) - command failed with exit code $ret, retrying in $retry_delay seconds (attempt $retry_count of $RETRIES)"
    sleep "$retry_delay"
    retry_delay=$((retry_delay * 2))
done

if [ -n "$AFTER_COMMAND" ]
then
    if [ $ret -ne 0 ];
    then
        echo "$(date) - command failed with exit code $ret, not executing AFTER_COMMAND"
    else
        eval "$AFTER_COMMAND"
        ret=$?
    fi
fi

exit "$ret"
