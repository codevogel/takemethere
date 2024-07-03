setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # Make file for test data
    mkdir -p /tmp/tmt_test_data
    export TMT_DATA_FILE=/tmp/tmt_test_data/.tmt_data
    cat <<HERE > $TMT_DATA_FILE
/tmp/tmt-test/foo
bar:/tmp/tmt-test/bar
baz:/tmp/tmt-test/baz
glorp
glarp:glorp
HERE

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/../src:$PATH"
}


@test "Prints entries in the expected format" {
    run tmt list
    assert_output "$(cat <<HERE
1| /tmp/tmt-test/foo
2| bar:/tmp/tmt-test/bar
3| baz:/tmp/tmt-test/baz
4| glorp
5| glarp:glorp
HERE
    )"
}

@test "Extracts target (line number) from fzf picker result" {

    fzf() { echo "1| foo"; }
    export -f fzf
    run tmt pick
    assert_output "1"
}

@test "Reads target (line number) from stdin when --no-fzf" {
    output=$(echo "1" | tmt pick --no-fzf | tail -n 1)
    assert_output "1"
}

@test "Reads target (alias) from stdin when --no-fzf" {
    output=$(echo "bar" | tmt pick --no-fzf | tail -n 1)
    assert_output "bar"
}
