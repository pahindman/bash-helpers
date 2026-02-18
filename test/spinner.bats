bats_require_minimum_version 1.5.0

setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	do_work() {
		echo "did some work"
	}

	do_work_with_automatic_spinner_at_cursor() {
		source spinner.bash
		automatic_spinner::start_at_cursor "Spinner..." 0.1
		do_work
		spinner::stop "done"
	}

	do_work_with_automatic_spinner_in_margin() {
		source spinner.bash
		automatic_spinner::start_in_margin "Spinner..." 0.1
		do_work
		spinner::stop "done"
	}

	do_work_with_manual_spinner_at_cursor() {
		source spinner.bash
		manual_spinner::start_at_cursor "Spinner..."
		do_work
		spinner::stop "done"
	}

	do_work_with_manual_spinner_in_margin() {
		source spinner.bash
		manual_spinner::start_in_margin "Spinner..."
		do_work
		spinner::stop "done"
	}
}

teardown() {
	:
}

@test "automatic spinner at cursor runs without error" {
	run --separate-stderr do_work_with_automatic_spinner_at_cursor
	assert_success
}

@test "automatic spinner at cursor prints start message" {
	run --separate-stderr do_work_with_automatic_spinner_at_cursor
	assert_stderr --regexp "Spinner...[ \b/\\|-]+"
}

@test "automatic spinner at cursor does not prevent normal output" {
	run --separate-stderr do_work_with_automatic_spinner_at_cursor
	assert_output "did some work"
}

@test "automatic spinner at cursor prints done message" {
	run --separate-stderr do_work_with_automatic_spinner_at_cursor
	assert_stderr --regexp "done$"
}

@test "automatic spinner in margin runs without error" {
	run --separate-stderr do_work_with_automatic_spinner_in_margin 3>&-
	assert_success
}

@test "automatic spinner in margin prints start message" {
	run --separate-stderr do_work_with_automatic_spinner_in_margin 3>&-
	assert_stderr --partial "Spinner..."
}

@test "automatic spinner in margin does not prevent normal output" {
	run --separate-stderr do_work_with_automatic_spinner_in_margin 3>&-
	assert_output "did some work"
}

@test "automatic spinner in margin prints done message" {
	run --separate-stderr do_work_with_automatic_spinner_in_margin 3>&-
	assert_stderr --partial "done"
}

@test "manual spinner at cursor runs without error" {
	run --separate-stderr do_work_with_manual_spinner_at_cursor
	assert_success
}

@test "manual spinner at cursor prints start message" {
	run --separate-stderr do_work_with_manual_spinner_at_cursor
	assert_stderr --regexp "Spinner...[ \b/\\|-]+"
}

@test "manual spinner at cursor does not prevent normal output" {
	run --separate-stderr do_work_with_manual_spinner_at_cursor
	assert_output "did some work"
}

@test "manual spinner at cursor prints done message" {
	run --separate-stderr do_work_with_manual_spinner_at_cursor
	assert_stderr --regexp "done$"
}

@test "manual spinner in margin runs without error" {
	run --separate-stderr do_work_with_manual_spinner_in_margin 3>&-
	assert_success
}

@test "manual spinner in margin prints start message" {
	run --separate-stderr do_work_with_manual_spinner_in_margin 3>&-
	assert_stderr --partial "Spinner..."
}

@test "manual spinner in margin does not prevent normal output" {
	run --separate-stderr do_work_with_manual_spinner_in_margin 3>&-
	assert_output "did some work"
}

@test "manual spinner in margin prints done message" {
	run --separate-stderr do_work_with_manual_spinner_in_margin 3>&-
	assert_stderr --partial "done"
}
