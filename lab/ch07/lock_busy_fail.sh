# shellcheck shell=bash
# Shows: the repository lock. A slow `cairn snapshot` (CAIRN_BWLIMIT=2048
# KiB/s on a 20 MiB tree) holds the lock; a second `cairn snapshot` on
# the same repository fails at once with exit status 4 and the message
# from the contract. The lab ends with that status 4, so it is a _fail
# lab; it exits 1 instead if the message differs.
src="${LAB_TMP}/src"
repo="$(realpath -m -- "${LAB_TMP}/repo")"
conf="${LAB_TMP}/cairn.conf"
mkdir "${src}" || exit 1
for ((n = 1; n <= 20; n++)); do
  head -c 1048576 /dev/zero >"${src}/file_${n}.dat" || exit 1
done
cairn -c "${conf}" init "${repo}" 2>/dev/null || exit 1
printf 'source = %s\n' "${src}" >>"${conf}"

echo '--- first snapshot, slow, in the background ---'
CAIRN_BWLIMIT=2048 CAIRN_NOW=20261031T090000Z \
  cairn -q -c "${conf}" snapshot >first.out 2>first.err &
first=$!
# 标记: rsync 开始写 partial 目录时, 第一个 cairn 一定已经拿到锁。
until compgen -G "${repo}/snapshots/*.partial" >/dev/null; do
  sleep 0.05
done
echo 'the first snapshot is running (its .partial directory exists)'

echo '--- second snapshot on the same repository ---'
CAIRN_NOW=20261031T100000Z cairn -c "${conf}" snapshot 2>second.err
status=$?
sed "s|${LAB_TMP}|<tmp>|" second.err
echo "second cairn exit status: ${status}"

echo '--- stop the first one ---'
kill -TERM "${first}"
wait "${first}"
echo "first cairn exit status: $?"

expected="cairn: error: another cairn is running on ${repo}"
if [[ "$(<second.err)" != "${expected}" ]]; then
  echo 'unexpected message' >&2
  exit 1
fi
exit "${status}"
