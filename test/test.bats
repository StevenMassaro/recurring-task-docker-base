setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/../src:$PATH"
}


@test "valid command" {
    export COMMAND="echo hello"
    run execute.sh
    assert_output 'hello'
}

@test "invalid command" {
    export COMMAND="asldkjaslkdj"
    run execute.sh
    assert_output --partial 'asldkjaslkdj: not found'
}

@test "valid command and valid after command" {
    export COMMAND="echo hello1"
    export AFTER_COMMAND="echo hello2"
    run execute.sh
    assert_output --partial 'hello1'
    assert_output --partial 'hello2'
}

@test "valid command and invalid after command" {
    bats_require_minimum_version 1.5.0
    export COMMAND="echo hello1"
    export AFTER_COMMAND="alskdjalksdj"
    run -127 execute.sh
    assert_output --partial 'hello1'
    assert_output --partial 'alskdjalksdj: not found'
}

@test "invalid command and valid after command" {
    export COMMAND="elkajsd"
    export AFTER_COMMAND="echo hello1"
    run execute.sh
    assert_output --partial 'elkajsd: not found'
    assert_output --partial 'command failed with exit code 127, not executing AFTER_COMMAND'
    refute_output 'hello1'
}

@test "default RETRIES does not retry a failed command" {
    attempts_file="/tmp/execute-retries-default-$BATS_TEST_NUMBER"
    rm -f "$attempts_file"
    export ATTEMPTS_FILE="$attempts_file"
    export COMMAND='attempts=$(cat "$ATTEMPTS_FILE" 2>/dev/null || echo 0); attempts=$((attempts + 1)); echo "$attempts" > "$ATTEMPTS_FILE"; false'

    run execute.sh
    [ "$status" -eq 1 ]
    run cat "$attempts_file"
    assert_output '1'
}

@test "retries stop after the command succeeds" {
    attempts_file="/tmp/execute-retries-success-$BATS_TEST_NUMBER"
    rm -f "$attempts_file"
    export ATTEMPTS_FILE="$attempts_file"
    export RETRIES=3
    export RETRY_BACKOFF=0
    export COMMAND='attempts=$(cat "$ATTEMPTS_FILE" 2>/dev/null || echo 0); attempts=$((attempts + 1)); echo "$attempts" > "$ATTEMPTS_FILE"; [ "$attempts" -ge 3 ]'
    export AFTER_COMMAND='echo after'

    run execute.sh
    [ "$status" -eq 0 ]
    assert_output --partial 'after'
    run cat "$attempts_file"
    assert_output '3'
}

@test "retries return the final failure and skip AFTER_COMMAND" {
    attempts_file="/tmp/execute-retries-failure-$BATS_TEST_NUMBER"
    rm -f "$attempts_file"
    export ATTEMPTS_FILE="$attempts_file"
    export RETRIES=2
    export RETRY_BACKOFF=0
    export COMMAND='attempts=$(cat "$ATTEMPTS_FILE" 2>/dev/null || echo 0); attempts=$((attempts + 1)); echo "$attempts" > "$ATTEMPTS_FILE"; sh -c "exit 7"'
    export AFTER_COMMAND='echo should-not-run'

    run execute.sh
    [ "$status" -eq 7 ]
    assert_output --partial 'attempt 1 of 2'
    assert_output --partial 'attempt 2 of 2'
    refute_output --partial 'should-not-run'
    run cat "$attempts_file"
    assert_output '3'
}

@test "retries use exponential backoff" {
    mock_bin="/tmp/execute-retries-backoff-bin-$BATS_TEST_NUMBER"
    sleep_log="/tmp/execute-retries-backoff-$BATS_TEST_NUMBER"
    rm -rf "$mock_bin" "$sleep_log"
    mkdir -p "$mock_bin"
    cat > "$mock_bin/sleep" <<'EOF'
#!/bin/sh
printf '%s\n' "$1" >> "$SLEEP_LOG"
EOF
    chmod +x "$mock_bin/sleep"
    export PATH="$mock_bin:$PATH"
    export SLEEP_LOG="$sleep_log"
    export RETRIES=2
    export RETRY_BACKOFF=2
    export COMMAND='sh -c "exit 1"'

    run execute.sh
    [ "$status" -eq 1 ]
    run cat "$sleep_log"
    assert_output '2
4'
}

@test "healthchecks are pinged for every command attempt" {
    mock_bin="/tmp/execute-retries-healthchecks-bin-$BATS_TEST_NUMBER"
    attempts_file="/tmp/execute-retries-healthchecks-attempts-$BATS_TEST_NUMBER"
    curl_log="/tmp/execute-retries-healthchecks-pings-$BATS_TEST_NUMBER"
    rm -rf "$mock_bin" "$attempts_file" "$curl_log"
    mkdir -p "$mock_bin"
    cat > "$mock_bin/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$4" >> "$CURL_LOG"
EOF
    chmod +x "$mock_bin/curl"
    export PATH="$mock_bin:$PATH"
    export CURL_LOG="$curl_log"
    export HEALTHCHECKS_URL='https://healthchecks.test/uuid'
    export ATTEMPTS_FILE="$attempts_file"
    export RETRIES=3
    export RETRY_BACKOFF=0
    export COMMAND='attempts=$(cat "$ATTEMPTS_FILE" 2>/dev/null || echo 0); attempts=$((attempts + 1)); echo "$attempts" > "$ATTEMPTS_FILE"; [ "$attempts" -ge 3 ]'

    run execute.sh
    [ "$status" -eq 0 ]
    run cat "$curl_log"
    assert_output "${HEALTHCHECKS_URL}/1
${HEALTHCHECKS_URL}/1
${HEALTHCHECKS_URL}/0"
}

@test "CHECK_LAST_RUNTIME with recent last runtime sleeps" {
    export CHECK_LAST_RUNTIME=true
    export ADJUST_FOR_RUNTIME=false
    export DELAY="2s"
    export LAST_RUNTIME_FILE="/tmp/last_runtime_recent_bats"
    export COMMAND="echo 'test'"

    # Create a last runtime file that is very recent (e.g., 1 second ago)
    recent_time=$(( $(date +%s) - 1 ))
    echo $recent_time > "$LAST_RUNTIME_FILE"

    # Run scheduler for a short time, capture output
    ./src/scheduler.sh > /tmp/scheduler_output_bats 2>&1 &
    scheduler_pid=$!
    sleep 3  # let it run for a few seconds
    kill $scheduler_pid 2>/dev/null || true
    wait $scheduler_pid 2>/dev/null || true

    # Check that the output indicates it decided to sleep due to recent last runtime
    grep -q "Last runtime was 1 seconds ago, sleeping for 1 seconds to reach 2s interval" /tmp/scheduler_output_bats || {
        # If the exact message is not found, try a more general pattern
        grep -E -q "Last runtime was [0-9]+ seconds ago, sleeping for [0-9]+ seconds to reach.*interval" /tmp/scheduler_output_bats || {
            cat /tmp/scheduler_output_bats
            false
        }
    }
}

@test "CHECK_LAST_RUNTIME with old last runtime does not sleep" {
    export CHECK_LAST_RUNTIME=true
    export ADJUST_FOR_RUNTIME=false
    export DELAY="2s"
    export LAST_RUNTIME_FILE="/tmp/last_runtime_old_bats"
    export COMMAND="echo 'test'"

    # Create a last runtime file that is old (e.g., 10 seconds ago)
    old_time=$(( $(date +%s) - 10 ))
    echo $old_time > "$LAST_RUNTIME_FILE"

    # Run scheduler for a short time, capture output
    ./src/scheduler.sh > /tmp/scheduler_output_bats 2>&1 &
    scheduler_pid=$!
    sleep 3  # let it run for a few seconds
    kill $scheduler_pid 2>/dev/null || true
    wait $scheduler_pid 2>/dev/null || true

    # Check that the output indicates it did not sleep because last runtime was old
    grep -E -q "Last runtime was [0-9]+ seconds ago \(>= .*\), not sleeping" /tmp/scheduler_output_bats || {
        cat /tmp/scheduler_output_bats
        false
    }
}