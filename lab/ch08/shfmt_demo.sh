# shellcheck shell=bash
# Shows: `shfmt -i 2 -bn -ci -d` prints the diff between a script and its
# formatted form (-i 2: two-space indent, -bn: binary operators such as
# | start the next line, -ci: case branches are indented). shfmt -d
# exits 1 when the file differs; the lab prints that status and exits 0.
# Formatting the result again changes nothing (status 0).
cd "${CAIRN_ROOT}/lab/ch08/fixtures" || exit 1
echo '$ shfmt -ln bash -i 2 -bn -ci -d ugly_script.txt'
shfmt -ln bash -i 2 -bn -ci -d ugly_script.txt
echo "shfmt -d exit status: $?"

echo '--- formatted twice ---'
shfmt -ln bash -i 2 -bn -ci ugly_script.txt \
  | shfmt -ln bash -i 2 -bn -ci -d
echo "second pass exit status: $?"
exit 0
