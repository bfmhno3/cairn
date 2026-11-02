# shellcheck shell=bash
# Shows: how long Cairn really is. wc -l of every file under bin/ and
# lib/, in C-locale order, and the total (the last line).
cd "${CAIRN_ROOT}" || exit 1
find bin lib -type f | LC_ALL=C sort | xargs wc -l
