# shellcheck shell=bash
# Logging helpers for cairn. Library: sourced by bin/cairn, not executed.
#
# All messages go to stderr so that stdout stays clean for data.

# 设为 1 时 cairn::log::info 不输出。
CAIRN_QUIET="${CAIRN_QUIET:-0}"

#######################################
# Print an error message to stderr.
# Arguments:
#   Message text.
# Outputs:
#   Writes "cairn: error: <message>" to stderr.
#######################################
cairn::log::err() {
  printf 'cairn: error: %s\n' "$*" >&2
}

#######################################
# Print an informational message to stderr unless quiet.
# Globals:
#   CAIRN_QUIET
# Arguments:
#   Message text.
# Outputs:
#   Writes "cairn: <message>" to stderr.
#######################################
cairn::log::info() {
  if [[ "${CAIRN_QUIET}" == 1 ]]; then
    return 0
  fi
  printf 'cairn: %s\n' "$*" >&2
}
