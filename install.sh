#!/bin/sh
#
# install.sh: install or remove cairn.
#
# Usage: install.sh [--prefix DIR] [--uninstall] [-h]
#
# POSIX sh only (checked with checkbashisms, shellcheck -s sh and dash),
# because an installer must run where bash may not be installed yet. The
# style guide's rule "Bash for everything" has this one exception.
#
# `local` is not POSIX, so no function here declares one. Functions that
# need scratch variables are written as subshell functions, name() ( ... ),
# which cannot leak their variables; the rest use the globals below.

set -eu

# 卸载时按此顺序 rmdir (只删空目录), 先深后浅。
readonly CREATED_DIRS='
  share/cairn/systemd
  share/cairn
  share/bash-completion/completions
  share/bash-completion
  lib/cairn
  lib
  bin
  share
'

# Parsed from the command line by main; used by the helpers below.
PREFIX="${HOME:-}/.local"
UNINSTALL=0

#######################################
# Print the usage text.
# Outputs:
#   Writes the text to stdout.
#######################################
usage() {
  cat <<'USAGE'
Usage: install.sh [--prefix DIR] [--uninstall] [-h]

Install cairn under DIR (default: $HOME/.local).

Options:
  --prefix DIR  install under DIR instead of $HOME/.local
  --uninstall   remove what install.sh installed, and the empty
                directories it created
  -h            show this help and exit

If DESTDIR is set, every path is placed below it (for packaging).
USAGE
}

#######################################
# Print an error message to stderr.
# Arguments:
#   Message text.
# Outputs:
#   Writes "install.sh: error: <message>" to stderr.
#######################################
err() {
  printf 'install.sh: error: %s\n' "$*" >&2
}

#######################################
# Call a command once per file cairn installs.
# Arguments:
#   Source directory, command name. The command is called as
#   COMMAND MODE SOURCE_FILE RELATIVE_DESTINATION.
# Returns:
#   The first non-zero status of the command.
#######################################
for_each_file() (
  src="$1"
  cmd="$2"
  "${cmd}" 755 "${src}/bin/cairn" bin/cairn || exit
  for f in "${src}"/lib/cairn/*; do
    [ -f "${f}" ] || continue
    "${cmd}" 644 "${f}" "lib/cairn/${f##*/}" || exit
  done
  "${cmd}" 644 "${src}/completions/cairn.bash" \
    share/bash-completion/completions/cairn || exit
  for f in "${src}"/contrib/systemd/*; do
    [ -f "${f}" ] || continue
    "${cmd}" 644 "${f}" "share/cairn/systemd/${f##*/}" || exit
  done
)

#######################################
# Install one file below the staging root.
# Globals:
#   ROOT (set by main)
# Arguments:
#   Mode, source file, destination relative to ROOT.
# Outputs:
#   Writes "installed <path>" to stdout.
# Returns:
#   Non-zero if the source is missing or a command fails.
#######################################
install_file() (
  mode="$1"
  from="$2"
  to="${ROOT}/$3"
  if [ ! -f "${from}" ]; then
    err "missing source file ${from}"
    exit 1
  fi
  mkdir -p -- "${to%/*}" || exit
  cp -- "${from}" "${to}" || exit
  chmod "${mode}" "${to}" || exit
  printf 'installed %s\n' "${to}"
)

#######################################
# Remove one installed file; a file that is not there is not an error.
# Globals:
#   ROOT (set by main)
# Arguments:
#   Mode (unused), source file (unused), destination relative to ROOT.
# Outputs:
#   Writes "removed <path>" to stdout.
#######################################
remove_file() (
  to="${ROOT}/$3"
  if [ -f "${to}" ]; then
    rm -f -- "${to}" || exit
    printf 'removed %s\n' "${to}"
  fi
)

#######################################
# Remove the directories install created, but only the empty ones.
# Globals:
#   ROOT, CREATED_DIRS
#######################################
remove_empty_dirs() (
  for d in ${CREATED_DIRS}; do
    rmdir -- "${ROOT}/${d}" 2>/dev/null || :
  done
)

#######################################
# Parse the command line into PREFIX and UNINSTALL.
# Globals:
#   PREFIX, UNINSTALL
# Arguments:
#   The command line.
# Outputs:
#   Writes usage to stdout for -h, errors to stderr.
# Returns:
#   0 to go on, 10 if the caller should exit 0 (help), 2 on usage error.
#######################################
parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --prefix)
        if [ "$#" -lt 2 ] || [ -z "$2" ]; then
          err "--prefix needs a directory"
          return 2
        fi
        PREFIX="$2"
        shift 2
        ;;
      --uninstall)
        UNINSTALL=1
        shift
        ;;
      -h)
        usage
        return 10
        ;;
      *)
        err "unknown option '$1'"
        err "run 'install.sh -h' for usage"
        return 2
        ;;
    esac
  done
}

#######################################
# Install or uninstall cairn.
# Globals:
#   PREFIX, UNINSTALL, DESTDIR (optional), ROOT (set here)
# Arguments:
#   The command line.
# Returns:
#   0 on success, 1 on failure, 2 on usage error.
#######################################
main() {
  status=0
  parse_args "$@" || status=$?
  case "${status}" in
    0) ;;
    10) return 0 ;;
    *) return "${status}" ;;
  esac

  # 去掉末尾的斜杠, 避免路径里出现 //; 前缀 "/" 因此得到空串, 路径照样成立。
  ROOT="${DESTDIR:-}"
  ROOT="${ROOT%/}${PREFIX%/}"

  # install.sh 所在目录就是源码目录; 不依赖 readlink -f 或 dirname。
  case "$0" in
    */*) src_dir="${0%/*}" ;;
    *) src_dir=. ;;
  esac
  src_dir="$(cd -- "${src_dir}" && pwd -P)" || return 1

  if [ "${UNINSTALL}" -eq 1 ]; then
    for_each_file "${src_dir}" remove_file || return 1
    remove_empty_dirs
    return 0
  fi

  if ! command -v bash >/dev/null 2>&1; then
    printf '%s\n' \
      'install.sh: warning: bash not found in PATH; cairn needs bash' >&2
  fi
  for_each_file "${src_dir}" install_file || return 1
}

main "$@"
