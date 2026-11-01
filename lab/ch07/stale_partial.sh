# shellcheck shell=bash
# Shows: SIGKILL cannot be trapped, so a killed `cairn snapshot` leaves
# its .partial directory behind (no trap ran). The next `cairn snapshot`
# takes the lock, prints `removing stale ...partial` and removes it.
# `set -m` puts the background job in its own process group, so one
# `kill -KILL` on the group stops cairn and its rsync together. Exits 1
# if the partial survives the second run.
set -m
src="${LAB_TMP}/src"
repo="${LAB_TMP}/repo"
conf="${LAB_TMP}/cairn.conf"
mkdir "${src}" || exit 1
for ((n = 1; n <= 20; n++)); do
  head -c 1048576 /dev/zero >"${src}/file_${n}.dat" || exit 1
done
cairn -c "${conf}" init "${repo}" 2>/dev/null || exit 1
printf 'source = %s\n' "${src}" >>"${conf}"

CAIRN_BWLIMIT=2048 CAIRN_NOW=20261031T090000Z \
  cairn -q -c "${conf}" snapshot >/dev/null 2>&1 &
pid=$!
until compgen -G "${repo}/snapshots/*.partial" >/dev/null; do
  sleep 0.05
done
kill -KILL -- "-${pid}"
wait "${pid}" 2>/dev/null
echo "first cairn exit status: $? (128 + 9)"
# 内核在进程死亡后才关闭它们的文件描述符, 等锁真正放开。
until flock -n "${repo}/.lock" true; do
  sleep 0.05
done
echo '--- left behind by the killed run ---'
ls "${repo}/snapshots"

echo '--- the next snapshot ---'
CAIRN_NOW=20261031T100000Z cairn -c "${conf}" snapshot
echo '--- snapshots now ---'
ls "${repo}/snapshots"
if compgen -G "${repo}/snapshots/*.partial" >/dev/null; then
  echo 'FAIL: a .partial directory is left'
  exit 1
fi
