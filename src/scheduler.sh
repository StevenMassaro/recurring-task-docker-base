#!/bin/sh
echo "$(date) - start scheduler"
while :; do
    echo "$(date) - execute"

    eval "$COMMAND"
    ret=$?

    if [ -n "$AFTER_COMMAND" ]
    then
        if [ $ret -ne 0 ];
        then
            echo "$(date) - command failed with exit code $ret, not executing AFTER_COMMAND"
        else
            eval "$AFTER_COMMAND"
        fi
    fi

    echo "$(date) - sleep for ${DELAY:-1d}"
    sleep "${DELAY:-1d}"
done
