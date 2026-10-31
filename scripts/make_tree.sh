#!/usr/bin/env bash
#
# Creates a fixture tree full of awkward file names for the chapter 2
# labs and, from chapter 5 on, for snapshot tests.
#
# Usage: scripts/make_tree.sh DIR [--big MB]
#
# DIR is created if needed and must be empty, otherwise exit status 1.
# --big MB adds big/file_NNN.bin, MB files of 1 MiB random data each.

set -o nounset
set -o pipefail

#######################################
# Print an error message to stderr.
# Arguments:
#   Message text.
# Outputs:
#   Writes "make_tree.sh: <message>" to stderr.
#######################################
err() {
  printf 'make_tree.sh: %s\n' "$*" >&2
}

#######################################
# Fill DIR with the fixture entries.
# Arguments:
#   Target directory (must exist, must be empty), big file count.
# Returns:
#   0 on success, non-zero if a command fails.
#######################################
build_tree() {
  local dir="$1"
  local big_mb="$2"
  cd -- "${dir}" || return 1

  printf 'plain\n' >plain.txt || return 1
  printf 'space\n' >'with space.txt' || return 1
  printf 'dash\n' >./-rf || return 1
  printf 'star\n' >'star*.txt' || return 1
  printf 'newline\n' >$'new\nline.txt' || return 1
  printf '中文\n' >中文.md || return 1
  printf 'hidden\n' >.hidden || return 1
  mkdir empty_dir || return 1
  mkdir -p nested/a/b || return 1
  printf 'deep\n' >nested/a/b/c.txt || return 1
  ln -s plain.txt link_to_plain || return 1

  if ((big_mb > 0)); then
    mkdir big || return 1
    local i
    local name
    for ((i = 1; i <= big_mb; i++)); do
      printf -v name 'big/file_%03d.bin' "${i}"
      head -c 1048576 /dev/urandom >"${name}" || return 1
    done
  fi
}

#######################################
# Parse arguments and build the tree.
# Arguments:
#   DIR [--big MB]
# Returns:
#   0 on success, 1 if DIR is not empty, 2 on usage errors.
#######################################
main() {
  local dir=''
  local big_mb=0
  if (($# == 0)); then
    err 'usage: make_tree.sh DIR [--big MB]'
    return 2
  fi
  dir="$1"
  shift
  if (($# > 0)); then
    if [[ "$1" != --big || $# != 2 || ! "${2:-}" =~ ^[0-9]+$ ]]; then
      err 'usage: make_tree.sh DIR [--big MB]'
      return 2
    fi
    big_mb="$2"
  fi

  if [[ -e "${dir}" && ! -d "${dir}" ]]; then
    err "${dir} is not a directory"
    return 1
  fi
  if [[ -d "${dir}" ]] && [[ -n "$(ls -A -- "${dir}")" ]]; then
    err "${dir} is not empty"
    return 1
  fi
  mkdir -p -- "${dir}" || return 1
  build_tree "${dir}" "${big_mb}"
}

main "$@"
