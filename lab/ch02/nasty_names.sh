# shellcheck shell=bash
# Shows: how many entries `for f in $(ls)` sees in the make_tree fixture
# compared with a glob and with find -print0.
export LC_ALL=C
tree="${LAB_TMP}/tree"
bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${tree}" || exit 1
cd "${tree}" || exit 1

ls_count=0
# shellcheck disable=SC2045 # BAD: deliberate
for f in $(ls); do
  ls_count=$((ls_count + 1))
done

dotglob_count=0
shopt -s dotglob
# shellcheck disable=SC2034 # f is only counted
for f in ./*; do
  dotglob_count=$((dotglob_count + 1))
done
shopt -u dotglob

glob_count=0
# shellcheck disable=SC2034 # f is only counted
for f in ./*; do
  glob_count=$((glob_count + 1))
done

find_count=0
while IFS= read -r -d ''; do
  find_count=$((find_count + 1))
done < <(find . -mindepth 1 -maxdepth 1 -print0)

all_count="$(find . -mindepth 1 -print0 | tr -cd '\0' | wc -c)"

echo "entries at top level (find -print0):  ${find_count}"
echo "iterations of for f in \$(ls):         ${ls_count}"
echo "iterations of for f in ./*:           ${glob_count}"
echo "iterations of ./* with dotglob:       ${dotglob_count}"
echo "entries in the whole tree (find):     ${all_count}"
echo "--- what \$(ls) produced, one word per line"
# shellcheck disable=SC2046 # BAD: deliberate
bash "${CAIRN_ROOT}/lab/ch02/args.sh" $(ls)
