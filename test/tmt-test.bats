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

@test "Can run tmt" {
    run tmt.sh
}

@test "Uses default if TMT_DATA_FILE is not set" {
    unset TMT_DATA_FILE
    run tmt.sh
    assert_output "Warning: TMT_DATA_FILE not set, using default, which resolves to /home/$(whoami)/.takemethere"
}

@test "Creates TMT_DATA_FILE if it does not exist" {
    export TMT_DATA_FILE="/tmp/tmt-test-data-that-should-not-exist"
    refute [ -f "$TMT_DATA_FILE" ]
    run tmt.sh
    assert [ -e "$TMT_DATA_FILE" ]
    assert_output "Creating data file at $TMT_DATA_FILE"
}

teardown() {
    rm -f "/tmp/tmt-test-data-that-should-not-exist"
}