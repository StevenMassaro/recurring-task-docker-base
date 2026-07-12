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
    assert_output --partial 'hello'
}

@test "invalid command" {
    export COMMAND="asldkjaslkdj"
    run execute.sh
    assert_output --partial 'asldkjaslkdj: command not found'
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
    assert_output --partial 'alskdjalksdj: command not found'
}

@test "invalid command and valid after command" {
    export COMMAND="elkajsd"
    export AFTER_COMMAND="echo hello1"
    run execute.sh
    assert_output --partial 'elkajsd: command not found'
    assert_output --partial 'command failed with exit code 127, not executing AFTER_COMMAND'
    refute_output 'hello1'
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