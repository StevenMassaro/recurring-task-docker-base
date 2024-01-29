#!/bin/sh
echo "$(date) - start scheduler"
while :; do
    echo "$(date) - execute"

    ./execute.sh

    echo "$(date) - sleep for ${DELAY:-1d}"
    sleep "${DELAY:-1d}"
done
