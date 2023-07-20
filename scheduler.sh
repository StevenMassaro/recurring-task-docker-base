#!/bin/sh
echo "$(date) - start scheduler"
while :; do
    echo "$(date) - execute"

    eval "$command"

    echo "$(date) - sleep for 1 day"
    sleep 1d
done
