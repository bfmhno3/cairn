# shellcheck shell=bash
# Shows: cairn snapshot copies every entry of the make_tree fixture,
# including names with spaces, a leading dash, a newline and a symlink.
# Exit 1 if the find -print0 counts of source and snapshot differ.
export LC_ALL=C

count_entries() {
  find "$1" -mindepth 1 -print0 | tr -cd '\0' | wc -c
}

src="${LAB_TMP}/tree"
repo="${LAB_TMP}/repo"
bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${src}" || exit 1

name="$(CAIRN_NOW=20261101T000000Z cairn snapshot "${repo}" "${src}")" \
  || exit 1
echo "snapshot name: ${name}"
copy="${repo}/snapshots/${name}${src}"

src_count="$(count_entries "${src}")"
copy_count="$(count_entries "${copy}")"
echo "source entries:   ${src_count}"
echo "snapshot entries: ${copy_count}"
if ((src_count != copy_count)); then
  echo 'MISMATCH' >&2
  exit 1
fi
echo 'counts match'
