# shellcheck shell=bash
# Shows: how read mangles lines unless used as IFS= read -r, and the
# last line without a trailing newline.
printf '  indented\\back\\slash\nlast no newline' >"${LAB_TMP}/in.txt"

echo '--- plain read ---'
# BAD: strips leading blanks, eats backslashes.
# shellcheck disable=SC2162
while read line; do
  echo "[${line}]"
done <"${LAB_TMP}/in.txt"

echo '--- IFS= read -r ---'
while IFS= read -r line; do
  echo "[${line}]"
done <"${LAB_TMP}/in.txt"

echo '--- IFS= read -r || [[ -n line ]] ---'
while IFS= read -r line || [[ -n "${line}" ]]; do
  echo "[${line}]"
done <"${LAB_TMP}/in.txt"
