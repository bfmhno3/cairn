# shellcheck shell=bash
# Shows: cairn diff between two snapshots: one file added, one deleted,
# one modified ("with space.txt", so paths with blanks are covered).
# Exits 1 if the output differs from the expected lines below.
src="${LAB_TMP}/src"
repo="${LAB_TMP}/repo"
conf="${LAB_TMP}/cairn.conf"
bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${src}" || exit 1
cairn -c "${conf}" init "${repo}" 2>/dev/null || exit 1
printf 'source = %s\n' "${src}" >>"${conf}"
old="$(CAIRN_NOW=20261031T090000Z cairn -q -c "${conf}" snapshot)" \
  || exit 1

# 改写的文件换了大小, 且先等 mtime 越过当前这一秒, rsync 一定会发现。
sleep 1.1
printf 'new file\n' >"${src}/added.txt"
rm "${src}/plain.txt"
printf 'space, changed\n' >"${src}/with space.txt"
new="$(CAIRN_NOW=20261031T100000Z cairn -q -c "${conf}" snapshot)" \
  || exit 1

# --relative 让快照里的路径带着源目录的绝对路径。
rel="./${src#/}"
cat >expected.txt <<EOF
A ${rel}/added.txt
D ${rel}/plain.txt
M ${rel}/with space.txt
EOF

echo "--- cairn diff ${old} ${new} ---"
cairn -c "${conf}" diff "${old}" "${new}" >actual.txt
echo "exit status: $?"
# 路径里的临时目录名每次都不同, 显示时换成 <src>。
sed "s|${rel}|<src>|" actual.txt
echo '--- same snapshot twice: no output ---'
cairn -c "${conf}" diff "${old}" "${old}"
echo "exit status: $?"
echo '--- unknown snapshot ---'
cairn -c "${conf}" diff "${old}" nosuch
echo "exit status: $?"
if ! diff expected.txt actual.txt >/dev/null; then
  echo 'cairn diff output differs from expected' >&2
  diff expected.txt actual.txt >&2
  exit 1
fi
echo 'matches the expected lines'
