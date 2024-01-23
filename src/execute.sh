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