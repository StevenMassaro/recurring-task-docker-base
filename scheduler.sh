#!/bin/sh
echo "$(date) - start scheduler"
while :; do
    echo "$(date) - execute"

    eval "$command"

    echo "$(date) - sleep for ${delay:-1d}"
    sleep "${delay:-1d}"
done
