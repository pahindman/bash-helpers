#!/bin/bash
# This script implements helpers for managing simple, but specialized, output on a
# terminal, which can be used to implement a progress bar or other status display. It is
# designed to be sourced by other scripts, which can use the margin to provide a visual
# indication of status.
# - Call bottom_margin::reserve with the number of lines to reserve at the bottom of the
#   terminal and the total number of lines in the terminal.
# - Call bottom_margin::replace_line to clear the specified line in the margin and replace it with
#   the specified text.
# - Call bottom_margin::erase to clear the entire bottom margin.
# - Call these functions from a SIGWINCH handler as well, otherwise resizing the terminal
#   will have unexpected results.
# - Ensure that the scroll region is restored to the full terminal when the script exits,
#   otherwise the terminal may be left in an unexpected state.
#
# Example usage:
#     #!/bin/bash
#
#     source terminal.bash
#
#     terminal::bottom_margin::reserve 2 $LINES
#     terminal::bottom_margin::replace_line 1 $LINES "Some status message"
#     terminal::bottom_margin::replace_line 2 $LINES "Some other status message"
#
#     # TODO: Setup a SIGWINCH handler to reconfigure the terminal margin on terminal resize
#
#     for ((i = 1; i <= 100; i++)); do
#         echo "Content in scroll region: $i"
#     done
#
#     # TODO: Setup an EXIT handler to do this cleanup even if the script exits abnormally
#     terminal::bottom_margin::erase 2 $LINES
#     terminal::bottom_margin::reserve 0 $LINES

### Public API ###

terminal::bottom_margin::reserve() {
	local margin_size=$1
	local total_lines=$2
	terminal_internal__bottom_margin_size=$margin_size

	terminal_internal::scroll_terminal_content_if_necessary "$margin_size"
	terminal::set_scroll_region 1 $((total_lines - margin_size))
}

terminal::bottom_margin::erase() {
	local margin_size=$1
	local total_lines=$2
	local top_margin_line=$((total_lines - margin_size + 1))
	local margin_line

	terminal::save_cursor_position
	for ((margin_line=top_margin_line; margin_line <= total_lines; margin_line++)); do
		terminal::move_cursor_to_row_column "$margin_line" 0
		terminal::erase_entire_cursor_line
	done
	terminal::restore_cursor_position
}

terminal::bottom_margin::replace_line() {
	local margin_line=$1
	local total_lines=$2
	local text=$3
	local line
	line=$(terminal_internal::translate_bottom_margin_line_to_terminal_line "$margin_line" "$total_lines")
	if [ -z "$line" ]; then
		return 0
	fi

	terminal::save_cursor_position
	terminal::move_cursor_to_row_column "$line" 0
	terminal::erase_from_cursor_to_end_of_line
	printf '%s' "$text" >&2 # print the new text
	terminal::restore_cursor_position
}

terminal::erase_from_cursor_to_end_of_line() {
	printf '\e[0K' >&2
}

terminal::erase_from_start_of_line_to_cursor() {
	printf '\e[1K' >&2
}

terminal::erase_entire_cursor_line() {
	printf '\e[2K' >&2
}

terminal::move_cursor_up() {
	printf '\e[%dA' "$1" >&2
}

terminal::move_cursor_down() {
	printf '\e[%dB' "$1" >&2
}

terminal::move_cursor_right() {
	printf '\e[%dC' "$1" >&2
}

terminal::move_cursor_left() {
	printf '\e[%dD' "$1" >&2
}

terminal::move_cursor_to_column() {
	printf '\e[%dG' "$1" >&2
}

terminal::move_cursor_to_row_column() {
	printf '\e[%d;%dH' "$1" "$2" >&2
}

terminal::move_cursor_to_location() {
	printf '\e[%sH' "$1" >&2
}

terminal::save_cursor_position() {
	printf '\e7' >&2
}

terminal::restore_cursor_position() {
	printf '\e8' >&2
}

terminal::hide_cursor() {
	printf '\e[?25l' >&2
}

terminal::show_cursor() {
	printf '\e[?25h' >&2
}

terminal::get_cursor_location() {
	# If stdin or stderr is not a terminal then we can't get the cursor location, so just
	# return an empty value, successfully.
	if [ ! -t 0 ] || [ ! -t 2 ]; then
		return 0
	fi

	# The response is in the format "\e[row;colR", so we need to parse it
	local cursor_location
	# shellcheck disable=SC2034
	IFS='[' read -p $'\E[6n' -s -r -d 'R' _ cursor_location
	echo "${cursor_location%R}"
}

terminal::get_row() {
	local cursor_location=$1

	local row column
	IFS=';' read -s -r row column <<< "$cursor_location"
	echo "${row}"
}

terminal::get_column() {
	local cursor_location=$1

	local row column
	IFS=';' read -s -r row column <<<"$cursor_location"
	echo "${column}"
}

terminal::set_scroll_region() {
	local first_line=$1
	local last_line=$2
	terminal::save_cursor_position
	terminal_internal::set_scroll_region "$first_line" "$last_line"
	terminal::restore_cursor_position
}

### Private internals ###

terminal_internal::scroll_terminal_content_if_necessary() {
	local margin_size=$1

	if [ "$margin_size" -eq 0 ]; then
		return 0
	fi

	local cursor_location
	cursor_location=$(terminal::get_cursor_location)

	# Print enough newlines to scroll any existing content up by the margin size, if
	# necessary.  If the cursor is above the margin then isn't necessary, but not
	# harmful either.  Either way we'll move the cursor back up at the end.
	local i
	for ((i = 0; i < margin_size; i++)); do
		printf '\n' >&2
	done

	if [ -z "$cursor_location" ]; then
		# Because we don't know the cursor column we have to print an extra line to ensure
		# previous output is not overwritten after moving the cursor around.
		printf '\n' >&2
	else
		local cursor_column
		cursor_column=$(terminal::get_column "$cursor_location")

		terminal::move_cursor_to_column "$cursor_column"
	fi

	terminal::move_cursor_up "$margin_size"
}

terminal_internal::set_scroll_region() {
	local first_line=$1
	local last_line=$2
	printf '\e[%d;%dr' "$first_line" "$last_line" >&2
}

terminal_internal::translate_bottom_margin_line_to_terminal_line() {
	# Margin lines are indexed from 1 at the top of the margin to margin_size at the
	# bottom of the margin. This function translates that to the corresponding line number
	# in the terminal, which is indexed from 1 at the top of the terminal to total_lines
	# at the bottom of the terminal.
	local margin_line=$1
	local total_lines=$2
	local margin_size=$terminal_internal__bottom_margin_size
	if [ -z "$margin_line" ] || [ -z "$total_lines" ] || [ -z "$margin_size" ]; then
		# If any of these are unknown then return an empty value, successfully.
		return 0
	fi
	echo "$((total_lines - margin_size + margin_line))"
}

### Initialization ###

# Ensure that checkwinsize is enabled to update LINES and COLUMNS when the terminal is resized
shopt -s checkwinsize
# this command ensures that LINES and COLUMNS are set
(:)
