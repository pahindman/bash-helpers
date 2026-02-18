#!/bin/bash
# This file implements a simple spinner to show progress during long-running operations.
# It can be sourced in other scripts to provide a visual indication of progress.
# - Call start_at_cursor with a message that will be displayed at the current
#   cursor location, with a spinner next to it.
#   OR
# - Call start_in_margin with a message that will be displayed in a
#   non-scrollable margin at the bottom of the terminal, with a spinner next to it.
# - Do your long-running work and the spinner will continue to be displayed.  If the
#   long-running work outputs information to the terminal then it will be interleaved with
#   the 'at_cursor' spinner.  Use the 'in_margin' spinner to avoid interleaved output.
# - Call stop_spinner to stop the spinner.  The 'at_cursor' spinner will print a
#   configurable completion message and the output will stay visible.  The 'in_margin'
#   spinner will be erased and the margin removed.
# - Sourcing this script installs a trap handlers for SIGWINCH and EXIT, preserving any
#   existing handlers.  If the sourcing script also installs trap handlers for SIGWINCH or
#   EXIT (after sourcing this script) then it must preserve the trap handlers installed by
#   this script.
#
# Example usage:
#     #!/bin/bash
#
#     source spinner.bash
#     automatic_spinner::start_at_cursor "Processing..."
#     # Your long-running command here
#     spinner::stop "done"

source terminal.bash

### Public API ###

automatic_spinner::start_at_cursor() {
	local message=$1
	local sleep_time=$2
	shift 2
	local spinner_chars=("${@:-${spinner_internal__DEFAULT_SPINNER_CHARS[@]}}")

	if [ -v spinner_internal__SPINNER_PID ]; then
		return 0
	fi

	coproc spinner_internal__SPINNER {
		automatic_spinner::internal::print_at_cursor "$message" "$sleep_time" "${spinner_chars[@]}"
	}
}

automatic_spinner::start_in_margin() {
	local message=$1
	local sleep_time=$2
	shift 2
	local spinner_chars=("${@:-${spinner_internal__DEFAULT_SPINNER_CHARS[@]}}")

	if [ -v spinner_internal__SPINNER_PID ]; then
		return 0
	fi

	trap::append_handler_for_signal spinner_internal::update_terminal_lines_for_spinner SIGWINCH

	coproc spinner_internal__SPINNER {
		automatic_spinner::internal::print_in_margin "$message" "$sleep_time" "${spinner_chars[@]}"
	}
}

manual_spinner::start_at_cursor() {
	local message=$1
	shift
	local spinner_chars=("${@:-${spinner_internal__DEFAULT_SPINNER_CHARS[@]}}")

	if [ -v spinner_internal__SPINNER_PID ]; then
		return 0
	fi

	coproc spinner_internal__SPINNER {
		manual_spinner::internal::print_at_cursor "$message" "${spinner_chars[@]}"
	}
}

manual_spinner::start_in_margin() {
	local message=$1
	shift
	local spinner_chars=("${@:-${spinner_internal__DEFAULT_SPINNER_CHARS[@]}}")

	if [ -v spinner_internal__SPINNER_PID ]; then
		return 0
	fi

	trap::append_handler_for_signal spinner_internal::update_terminal_lines_for_spinner SIGWINCH

	coproc spinner_internal__SPINNER {
		manual_spinner::internal::print_in_margin "$message" "${spinner_chars[@]}"
	}
}

manual_spinner::tick() {
	# Send a message to the spinner process to update the LINES value, which will also
	# cause it to redraw itself.
	spinner_internal::update_terminal_lines_for_spinner
}

spinner::stop() {
	local message=${1:-"done"}

	spinner_internal::tell_spinner_to_quit "$message"
	if [ -v spinner_internal__SPINNER_PID ]; then
		trap::remove_handler_for_signal spinner_internal::update_terminal_lines_for_spinner SIGWINCH
		wait "${spinner_internal__SPINNER_PID}"
		unset spinner_internal__SPINNER_PID
	fi
}

### Private internals ###

# shellcheck disable=SC1003
spinner_internal__DEFAULT_SPINNER_CHARS=('/' '-' '\' '|')

spinner_internal::configure_terminal() {
	terminal::bottom_margin::reserve 1 "$LINES"
}

spinner_internal::restore_terminal_and_erase_spinner() {
	terminal::bottom_margin::erase 1 "$LINES"
	terminal::bottom_margin::reserve 0 "$LINES"
}

spinner_internal::update_terminal_lines_for_spinner() {
	if [ -v spinner_internal__SPINNER ]; then
		echo "$LINES" >&"${spinner_internal__SPINNER[1]}"
	fi
}

spinner_internal::tell_spinner_to_quit() {
	local message=$1
	local FS=$'\x1C'

	if [ -v spinner_internal__SPINNER ]; then
		echo "q$FS$message" >&"${spinner_internal__SPINNER[1]}"
	fi
}

source trap.bash
automatic_spinner::internal::print_in_margin() {
	local message=$1
	local sleep_time=$2
	shift 2
	local spinner_chars=("${@}")

	trap::append_handler_for_signal spinner_internal::restore_terminal_and_erase_spinner EXIT
	spinner_internal::configure_terminal
	terminal::bottom_margin::replace_line 1 "$LINES" "${message}${spinner_chars[-1]}"

	while true; do
		if read -t 0; then
			IFS=$'\x1C' read -r msg1 msg2
			if [[ "$msg1" == "q" ]]; then
				terminal::bottom_margin::replace_line 1 "$LINES" "${message}${msg2}"
				spinner_internal::restore_terminal_and_erase_spinner
				trap::remove_handler_for_signal spinner_internal::restore_terminal_and_erase_spinner EXIT
				return 0
			else
				LINES=$msg1
			fi
		else
			# No new message, just continue spinning with the current LINES value
			:
		fi
		local spinner_char
		for spinner_char in "${spinner_chars[@]}"; do
			terminal::bottom_margin::replace_line 1 "$LINES" "${message}${spinner_char}"
			sleep "$sleep_time"
		done
	done
}

automatic_spinner::internal::print_at_cursor() {
	local message=$1
	local sleep_time=$2
	shift 2
	local spinner_chars=("${@}")

	terminal::hide_cursor
	printf "%s " "$message" >&2

	while true; do
		if read -t 0; then
			IFS=$'\x1C' read -r msg1 msg2
			if [ "$msg1" == "q" ]; then
				printf "\b%s\n" "$msg2" >&2
				return 0
			else
				LINES=$msg1
			fi
		else
			# No new message, just continue spinning
			:
		fi
		local spinner_char
		for spinner_char in "${spinner_chars[@]}"; do
			terminal::hide_cursor
			printf "\b%s" "$spinner_char" >&2
			sleep "$sleep_time"
		done
	done
}

manual_spinner::internal::print_in_margin() {
	local message=$1
	shift
	local spinner_chars=("${@}")

	trap::append_handler_for_signal spinner_internal::restore_terminal_and_erase_spinner EXIT
	spinner_internal::configure_terminal
	terminal::bottom_margin::replace_line 1 "$LINES" "${message}${spinner_chars[-1]}"

	while true; do
		IFS=$'\x1C' read -r msg1 msg2
		if [[ "$msg1" == "q" ]]; then
			terminal::bottom_margin::replace_line 1 "$LINES" "${message}${msg2}"
			spinner_internal::restore_terminal_and_erase_spinner
			trap::remove_handler_for_signal spinner_internal::restore_terminal_and_erase_spinner EXIT
			return 0
		else
			LINES=$msg1
			local spinner_char="${spinner_chars[0]}"
			terminal::bottom_margin::replace_line 1 "$LINES" "${message}${spinner_char}"

			# rotate spinner chars so that the next one will be different
			spinner_chars=("${spinner_chars[@]:1}" "${spinner_char[0]}")
		fi
	done
}

manual_spinner::internal::print_at_cursor() {
	local message=$1
	shift
	local spinner_chars=("${@}")

	terminal::hide_cursor
	printf "%s " "$message" >&2

	while true; do
		IFS=$'\x1C' read -r msg1 msg2
		if [ "$msg1" == "q" ]; then
			printf "\b%s\n" "$msg2" >&2
			return 0
		else
			LINES=$msg1
			local spinner_char="${spinner_chars[0]}"
			terminal::hide_cursor
			printf "\b%s" "$spinner_char" >&2

			# rotate spinner chars so that the next one will be different
			spinner_chars=("${spinner_chars[@]:1}" "${spinner_chars[0]}")
		fi
	done
}

