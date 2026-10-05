bats_require_minimum_version 1.5.0

setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	LINES=24
	COLUMNS=80
}

# bats file_tags=terminal

@test "terminal bottom margin reserve configures the reserved lines and translates line numbers" {
	source terminal.bash
	terminal::bottom_margin::reserve 2 24 >/dev/null 2>&1
	assert_equal "$terminal_internal__bottom_margin_size" "2"

	run bash -c '
		source terminal.bash
		terminal::bottom_margin::reserve 2 24 >/dev/null 2>&1
		printf "%s\n" "$(terminal_internal::translate_bottom_margin_line_to_terminal_line 1 24)"
	'
	assert_success
	assert_output "23"
}

@test "terminal bottom margin replace_line emits the expected cursor movement and text" {
	run bash -c '
		source terminal.bash
		terminal::bottom_margin::reserve 2 24
		terminal::bottom_margin::replace_line 1 24 "margin text"
	'
	assert_success
	assert_output --partial $'\e[23;0H'
	assert_output --partial $'\e[0K'
	assert_output --partial "margin text"
}

@test "terminal bottom margin erase clears each line in the reserved region" {
	run bash -c '
		source terminal.bash
		terminal::bottom_margin::reserve 2 24
		terminal::bottom_margin::erase 2 24
	'
	assert_success
	assert_output --partial $'\e[23;0H'
	assert_output --partial $'\e[24;0H'
	assert_output --partial $'\e[2K'
}

@test "terminal get_cursor_location returns the expected value" {
	run bash -c '
		source terminal.bash
		printf "\e[12;34R" | terminal::internal::get_cursor_location 2>/dev/null
	'
	assert_success
	assert_output "12;34"
}

@test "terminal get_row returns the expected value" {
	run bash -c '
		source terminal.bash
		terminal::get_row "12;34"
	'
	assert_success
	assert_output "12"
}

@test "terminal get_column returns the expected value" {
	run bash -c '
		source terminal.bash
		terminal::get_column "12;34"
	'
	assert_success
	assert_output "34"
}

@test "terminal set_scroll_region preserves cursor state while configuring the scroll region" {
	run bash -c '
		source terminal.bash
		terminal::set_scroll_region 1 20
	'
	assert_success
	assert_output --partial $'\e7'
	assert_output --partial $'\e[1;20r'
	assert_output --partial $'\e8'
}
