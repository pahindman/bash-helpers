#!/bin/sh
# This script is a small wrapper around the 'getopt' tool and is designed to be sourced by
# other scripts rather than executed directly. To use it from your own script, first
# define the shell variables LONGOPTS, SHORTOPTS, PROGRAM_NAME, and PROGRAM_ARGUMENTS in
# order to configure how to parse arguments, then source this script.  This script uses
# getopt to parse the arguments to your script ($@) and puts them into a canonical order
# that can be iterated over in order to implement higher level logic and that reads
# option/argument values.
#
# Usage example:
#
#   #!/bin/bash
#   LONGOPTS=help,opt:
#   SHORTOPTS=ho:
#   PROGRAM_NAME=$(basename "$0")
#
#   . getopt.bash
#
#   while true; do
#       opt=$1
#       shift
#       case "$opt" in
#           -h|--help)
#               echo "Usage: $0 [-h|--help] [-o|--opt]"
#               exit 0
#               ;;
#           -o|--opt)
#               option_value="$1"
#               shift
#               ;;
#           --)
#               break
#               ;;
#           *)
#               echo "Error: getopt was configured incorrectly."
#               echo "Error: Contact the author of '$0'"
#               exit 3
#               ;;
#       esac
#   done
#
#   # do stuff
#   echo "option was set to: $option_value"
#   echo "non-option arguments: $@"

# ignore errexit with `&& true`
getopt --test >/dev/null 2>&1 && true
if [ $? -ne 4 ]; then
    echo "This script requires 'getopt', but couldn't find it."
    exit 1
fi

# -temporarily store output to be able to check for errors
# -use '--options' to activate quoting/enhanced mode
# -pass arguments via '-- "$@"' to separate them correctly
# -if getopt fails, it writes to stderr
getopt_internal__OUTPUT=$(getopt --options="${SHORTOPTS}" --longoptions="${LONGOPTS}" --name="${PROGRAM_NAME:-$0}" -- "${PROGRAM_ARGUMENTS[@]:-$@}") || exit 2

# read getopt’s output this way to handle the quoting right, and re-set the $@ arguments
# to be what getopt produced.
eval set -- "$getopt_internal__OUTPUT"

unset getopt_internal__OUTPUT
