setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
}

teardown() {
	:
}

@test "appending a handler for a signal that has no existing handlers works" {
	source trap.bash
	trap::append_handler_for_signal first_test_handler EXIT
	run trap -p EXIT
	assert_output --partial "first_test_handler"
}

@test "appending a second handler works" {
	source trap.bash
	trap::append_handler_for_signal first_test_handler EXIT
	trap::append_handler_for_signal second_test_handler EXIT
	run trap -p EXIT
	assert_output --partial "first_test_handler"
	assert_output --partial "second_test_handler"
}

@test "removing first handler works and leaves second handler intact" {
	source trap.bash
	trap::append_handler_for_signal first_test_handler EXIT
	trap::append_handler_for_signal second_test_handler EXIT
	trap::remove_handler_for_signal first_test_handler EXIT
	run trap -p EXIT
	refute_output --partial "first_test_handler"
	assert_output --partial "second_test_handler"
}

@test "removing second handler works and leaves first handler intact" {
	source trap.bash
	trap::append_handler_for_signal first_test_handler EXIT
	trap::append_handler_for_signal second_test_handler EXIT
	trap::remove_handler_for_signal second_test_handler EXIT
	run trap -p EXIT
	assert_output --partial "first_test_handler"
	refute_output --partial "second_test_handler"
}

@test "appending another copy of first handler works" {
	source trap.bash
	trap::append_handler_for_signal first_test_handler EXIT
	trap::append_handler_for_signal second_test_handler EXIT
	trap::append_handler_for_signal first_test_handler EXIT
	run trap -p EXIT
	assert_output --regexp ".*first_test_handler.*second_test_handler.*first_test_handler.*"
}

@test "removing middle handler works" {
	source trap.bash
	trap::append_handler_for_signal first_test_handler EXIT
	trap::append_handler_for_signal second_test_handler EXIT
	trap::append_handler_for_signal first_test_handler EXIT
	trap::remove_handler_for_signal second_test_handler EXIT
	run trap -p EXIT
	assert_output --regexp ".*first_test_handler.*first_test_handler.*"
	refute_output --partial "second_test_handler"
}

@test "adding handler with whitepace works" {
	source trap.bash
	trap::append_handler_for_signal 'echo   "  hello"  ' EXIT
	run trap -p EXIT
	assert_output --partial "echo   "  hello"  "
}

@test "removing handler with whitepace works" {
	source trap.bash
	trap::append_handler_for_signal 'echo   "  hello"  ' EXIT
	trap::remove_handler_for_signal 'echo   "  hello"  ' EXIT
	run trap -p EXIT
	refute_output --partial "echo   "  hello"  "
}
