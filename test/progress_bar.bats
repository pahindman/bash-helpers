bats_require_minimum_version 1.5.0

setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	do_work() {
		local time=0.01
		local total_work=10
		local i
		for ((i = 0; i < total_work; i++)); do
			sleep "$time"
			progress_bar::update -c "work done " -n "$i" -t "$total_work" >&2
		done
		progress_bar::update -c "work done " -n "$total_work" -t "$total_work" >&2
		echo "did some work"
	}

	do_work_with_margin_progress_bar() {
		source progress_bar.bash
		progress_bar::start
		do_work
		progress_bar::stop
	}
}

teardown() {
	:
}

@test "progress bar in margin runs without error" {
	run do_work_with_margin_progress_bar
	assert_success
}

@test "progress bar in margin prints caption" {
	run --separate-stderr do_work_with_margin_progress_bar
	assert_stderr --partial "work done"
}

@test "progress bar in margin does not prevent normal output" {
	run --separate-stderr do_work_with_margin_progress_bar
	assert_output "did some work"
}

@test "progress bar in margin prints complete progress" {
	run --separate-stderr do_work_with_margin_progress_bar
	assert_stderr --regexp ".*\(100%\).*\[.*\]"
}
