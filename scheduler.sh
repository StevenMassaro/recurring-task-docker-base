#!/bin/sh
echo "$(date) - start scheduler"
while :; do
    echo "$(date) - execute"

    eval "$COMMAND"

    echo "$(date) - sleep for ${DELAY:-1d}"
    sleep "${DELAY:-1d}"
done
