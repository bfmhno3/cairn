# shellcheck shell=bash
# Shows: two cairn snapshots of a 50 MiB tree where one file changed
# between them. Unchanged files are hard links (same inode, link count
# 2), so the second snapshot adds only the changed file: du over both
# together is about one snapshot plus 1 MiB, not two.
src="${LAB_TMP}/src"
repo="${LAB_TMP}/repo"
conf="${LAB_TMP}/cairn.conf"
export TZ=UTC
bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${src}" --big 50 || exit 1
cairn -c "${conf}" init "${repo}" 2>/dev/null || exit 1
printf 'source = %s\n' "${src}" >>"${conf}"

first="$(CAIRN_NOW=20261031T090000Z cairn -q -c "${conf}" snapshot)" \
  || exit 1
# 只改一个 1 MiB 的文件。
head -c 1048576 /dev/urandom >"${src}/big/file_025.bin"
second="$(CAIRN_NOW=20261031T100000Z cairn -q -c "${conf}" snapshot)" \
  || exit 1

# --relative 把源目录的绝对路径原样放进快照里。
rel="${src#/}"
a="${repo}/snapshots/${first}/${rel}/big"
b="${repo}/snapshots/${second}/${rel}/big"

echo '--- link count and inode of two files in both snapshots ---'
for f in file_001.bin file_025.bin; do
  printf '%s: ' "${f}"
  stat -c '%h links, inode %i' "${a}/${f}" "${b}/${f}" | paste -sd '|'
done

echo '--- how many big files share an inode with the first snapshot ---'
shared=0
for f in "${a}"/*.bin; do
  if [[ "${f}" -ef "${b}/${f##*/}" ]]; then
    shared=$((shared + 1))
  fi
done
echo "${shared} of 50 are hard links"

echo '--- du -s --block-size=1, one snapshot at a time ---'
du_a="$(du -s --block-size=1 "${repo}/snapshots/${first}" | cut -f1)"
du_b="$(du -s --block-size=1 "${repo}/snapshots/${second}" | cut -f1)"
echo "first alone:   ${du_a} bytes"
echo "second alone:  ${du_b} bytes (every link counts)"

echo '--- du over both in one call: shared inodes are counted once ---'
readarray -t rows < <(du -s --block-size=1 "${repo}/snapshots/${first}" \
  "${repo}/snapshots/${second}" | cut -f1)
added="${rows[1]}"
both=$((rows[0] + rows[1]))
echo "first:  ${rows[0]} bytes"
echo "second: ${added} bytes (only what the first does not have)"
echo "both together: ${both} bytes"
printf 'second / first: %d.%d%%\n' "$((added * 100 / du_a))" \
  "$((added * 1000 / du_a % 10))"
printf 'both / (2 x first): %d.%d%%\n' "$((both * 100 / (2 * du_a)))" \
  "$((both * 1000 / (2 * du_a) % 10))"

echo '--- cairn list ---'
cairn -c "${conf}" list
