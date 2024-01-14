#!/bin/sh
echo "$(date) - start scheduler"
while :; do
    echo "$(date) - execute"

    eval "$COMMAND"

    if [[ ! -z "$AFTER_COMMAND" ]]
    then
        eval "$AFTER_COMMAND"
    fi

    echo "$(date) - sleep for ${DELAY:-1d}"
    sleep "${DELAY:-1d}"
done
