#!/bin/bash
# This file implements a progress bar to show progress during long-running operations.
# It can be sourced in other scripts and used to provide a visual indication of progress.
# - Call progress_bar::start to initialize the progress bar.
# - Call the progress_bar::update function to update the progress bar. It takes the following options:
#     -b: character to use for the filled portion of the bar (default: '#')
#     -c: string to use as the caption (prefix) for the progress bar (default: '')
#     -e: character to use for the empty portion of the bar (default: ' ')
#     -n: current progress (required)
#     -t: total progress (required)
# - Call stop_progress_bar to clean up the progress bar and restore the terminal configuration.
# - Sourcing this script installs trap handlers for SIGWINCH and EXIT, preserving any
#   existing handlers. If the sourcing script also installs trap handlers for SIGWINCH or
#   EXIT (after sourcing this script) then it must preserve the trap handlers installed by
#   this script.
#
# Example usage:
#     #!/bin/bash
#
#     source progress_bar.bash
#
#	  progress_bar::start
#     for i in {1..100}; do
#         sleep 0.1 # simulated work
#         progress_bar::update_progress_bar -c "stuff " -n "$i" -t 100
#     done
#	  progress_bar::stop_progress_bar

### Public API ###

progress_bar::start() {
	trap::append_handler_for_signal progress_bar_internal::configure_terminal SIGWINCH
	trap::append_handler_for_signal progress_bar_internal::restore_terminal_and_erase_progress_bar EXIT

	progress_bar_internal::configure_terminal
}

progress_bar::update() {
	terminal::bottom_margin::replace_line 1 "$LINES" "$(progress_bar_internal::generate_progress_bar_string "$@")"
}

progress_bar::stop() {
	progress_bar_internal::restore_terminal_and_erase_progress_bar

	trap::remove_handler_for_signal progress_bar_internal::configure_terminal SIGWINCH
	trap::remove_handler_for_signal progress_bar_internal::restore_terminal_and_erase_progress_bar EXIT
}

### Private internals ###

source terminal.bash
source trap.bash

progress_bar_internal::generate_progress_bar_string() {
	local caption='Progress:'
	local bar_char='#'
	local empty_char=' '
	local num
	local total

	local OPTARG OPTIND opt num total
	while getopts 'b:c:e:n:t:' opt; do
		case "$opt" in
			b) bar_char=$OPTARG;;
			c) caption=$OPTARG;;
			e) empty_char=$OPTARG;;
			n) num=$OPTARG;;
			t) total=$OPTARG;;
			*) echo "bad option: $opt" >&2; exit 1;;
		esac
	done

	if [ -z "$num" ]; then
		echo 'missing num argument' >&2
		exit 1
	fi
	if [ -z "$total" ]; then
		echo 'missing total argument' >&2
		exit 1
	fi

	local perc_done=$((num * 100 / total))
	local stats
	printf -v stats "[%*u/%u] (%3u%%)" "${#total}" "$num" "$total" "$perc_done"
	local prefix="$caption $stats"
	local suffix=""
	local length=$((COLUMNS - ${#prefix} - ${#suffix} - 3)) # 3 extra chars for the brackets and space
	local num_bars=$((perc_done * length / 100))

	local reverse_on=$'\x1b[7m'
	local reverse_off=$'\x1b[27m'
	local progress_bar="$reverse_on$prefix$reverse_off"
	progress_bar+=' ['
	local i
	for ((i = 0; i < num_bars; i++)); do
		progress_bar+=$bar_char
	done
	for ((i = num_bars; i < length; i++)); do
		progress_bar+=$empty_char
	done
	progress_bar+=']'
	progress_bar+=$suffix
	echo "$progress_bar"
}

progress_bar_internal::configure_terminal() {
	terminal::bottom_margin::reserve 1 $LINES
}

progress_bar_internal::restore_terminal_and_erase_progress_bar() {
	terminal::bottom_margin::erase 1 $LINES
	terminal::bottom_margin::reserve 0 $LINES
}
