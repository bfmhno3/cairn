# shellcheck shell=bash
# Shows: a name that is not a builtin, function or file on PATH gives 127.
no_such_command_cairn
status=$?
echo "exit status: ${status}"
exit "${status}"
