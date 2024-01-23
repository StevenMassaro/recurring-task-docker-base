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
    refute_output 'hello1'
}
