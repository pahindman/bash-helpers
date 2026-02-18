setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

	# get the containing directory of this file
	DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
	PATH="$DIR:$PATH"
}

teardown() {
	:
}

@test "passing no arguments and no options to use_getopt works" {
	run use_getopt
	assert_output $'option was set to: \nnon-option arguments: '
}

@test "passing arguments but no option to use_getopt works" {
	run use_getopt foo bar baz
	assert_output $'option was set to: \nnon-option arguments: foo bar baz'
}

@test "passing no arguments but an option to use_getopt works" {
	run use_getopt --opt foo
	assert_output $'option was set to: foo\nnon-option arguments: '
}

@test "passing arguments and an option to use_getopt works" {
	run use_getopt --opt foo bar baz
	assert_output $'option was set to: foo\nnon-option arguments: bar baz'
}

@test "passing non-option argument after '--' works" {
	run use_getopt bar baz -- --opt foo
	assert_output $'option was set to: \nnon-option arguments: bar baz --opt foo'
}
