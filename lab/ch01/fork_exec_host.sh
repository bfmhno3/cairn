# shellcheck shell=bash
# Shows: the execve calls behind `bash -c '/usr/bin/env true; echo hi'`.
# Host only: needs strace and ptrace permission.
strace -f -e trace=execve,clone,clone3 -o "${LAB_TMP}/trace" \
  bash -c '/usr/bin/env true; echo hi'
grep execve "${LAB_TMP}/trace" \
  | sed -E 's/^[0-9]+ +//; s/, 0x[0-9a-f]+ \/\* [0-9]+ vars \*\/\)/)/'
