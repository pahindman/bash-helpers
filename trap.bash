#!/bin/bash
# This file implements functions for adding and removing trap handlers and is intended to
# be sourced by other scripts that need to manage trap handlers. This is particularly
# useful for scripts that need to perform cleanup actions on EXIT or handle terminal
# resize events (SIGWINCH) without interfering with each other.
# - Call append_handler_for_signal to append the specified handler to the end of the list
#   of trap handlers for the specified signal, allowing multiple handlers to coexist for
#   the same signal.  The handlers will be called in sequence when the signal occurs.
# - Call remove_handler_for_signal to remove the specified handler from the list of trap
#   handlers for the specified signal.  Only the last handler in the list is removed.
#   Note: If no matching handler is found then this function does nothing, successfully.
#   Note: You can add statements as handlers, e.g. 'echo   "do    XYZ"', but this function
#   only removes a handler that is textually identical (including whitespace) to the
#   specified handler, so using a handler function is recommended.
#
# Example usage:
#     #!/bin/bash
#
#     handle_terminal_resize() {
#         # do resize stuff
#     }
#
#     source trap.bash
#     trap::append_handler_for_signal handle_terminal_resize SIGWINCH
#
#     # Main script logic
#
#     trap::remove_handler_for_signal handle_terminal_resize SIGWINCH

### Public API ###

trap::append_handler_for_signal() {
	local new_handler=$1
	local signal=$2

	# Get the existing trap handler for the signal, if any
	local existing_handler
	existing_handler=$(trap_internal::get_handler_for_signal "$signal")

	# If there is an existing handler, append the new handler to it
	if [ -n "$existing_handler" ]; then
		# shellcheck disable=SC2064
		trap "$existing_handler;$new_handler" "$signal"
	else
		# shellcheck disable=SC2064
		trap "$new_handler" "$signal"
	fi
}

trap::remove_handler_for_signal() {
	local handler_to_remove=$1
	local signal=$2

	# Get the existing trap handler for the signal, if any
	local existing_handler
	existing_handler=$(trap_internal::get_handler_for_signal "$signal")

	# If there is an existing handler, remove the specified handler from it
	if [ -n "$existing_handler" ]; then
		local updated_handler

		# Remove last handler_to_remove and clean up any leading or trailing semicolons and whitespace
		updated_handler=$(echo "$existing_handler" | sed "s/\(.*\)$handler_to_remove/\1/;s/^[; ]*//;s/[; ]*$//;s/;;*/;/g")

		if [ -n "$updated_handler" ]; then
			# shellcheck disable=SC2064
			trap "$updated_handler" "$signal"
		else
			trap - "$signal"
		fi
	fi
}

### Private internals ###

trap_internal::get_handler_for_signal() {
	local signal=$1
	local handler
	handler=$(trap -p "$signal")
	handler=${handler#*\'}
	handler=${handler%%\'*}
	echo "$handler"
}
