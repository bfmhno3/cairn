# shellcheck shell=bash
# Shows: a file name may contain a newline, so `find | wc -l` counts
# wrong; counting NUL bytes with -print0 is exact. `sort -z` and
# `xargs -0` keep NUL-separated names intact.
bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${LAB_TMP}/tree" || exit 1
cd "${LAB_TMP}/tree" || exit 1

echo '--- find . -type f | wc -l ---'
find . -type f | wc -l

printf '%s\n' '--- find . -type f -print0 | tr -cd "\0" | wc -c ---'
find . -type f -print0 | tr -cd '\0' | wc -c

echo '--- the name with a newline, shown with %q ---'
find . -name 'new*' -type f -print0 | xargs -0 printf '%q\n'

echo '--- sort -z keeps names whole ---'
find . -type f -print0 | LC_ALL=C sort -z | tr '\0\n' '|~'
echo

echo '--- xargs without -0: one printed line per argument it saw ---'
# BAD: xargs splits on blanks and newlines, so names fall into pieces.
# shellcheck disable=SC2038
find . -type f | xargs -n 1 printf '.%.0s\n' | wc -l
echo '--- xargs -0: one argument per file ---'
find . -type f -print0 | xargs -0 -n 1 printf '.%.0s\n' | wc -l
