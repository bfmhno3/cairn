# shellcheck shell=bash
# Shows: SIGINT during `cairn snapshot`. A slow snapshot (CAIRN_BWLIMIT
# =2048 KiB/s, 20 MiB tree) gets `kill -INT` 1 s after its .partial
# directory appeared. The INT trap stops rsync, removes the partial and
# logs status=interrupted; cairn exits 130. Checks the status, that no
# *.partial is left and the last log line; exits 1 if any check fails.
# `set -m` keeps SIGINT from being ignored in the background job.
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
  cairn -c "${conf}" snapshot >out.txt 2>err.txt &
pid=$!
until compgen -G "${repo}/snapshots/*.partial" >/dev/null; do
  sleep 0.05
done
echo 'partial directory exists: the snapshot is running'
sleep 1
kill -INT "${pid}"
wait "${pid}"
status=$?
echo "cairn exit status: ${status}"
echo '--- cairn stderr ---'
cat err.txt

fail=0
if ((status == 130)); then
  echo 'ok: exit status 130'
else
  echo 'FAIL: expected exit status 130'
  fail=1
fi
if compgen -G "${repo}/snapshots/*.partial" >/dev/null; then
  echo 'FAIL: a .partial directory is left'
  fail=1
else
  echo 'ok: no .partial directory left'
fi
last="$(tail -n 1 "${repo}/logs/cairn.log")"
echo "last log line: ${last}"
if [[ "${last}" == *'status=interrupted'* ]]; then
  echo 'ok: last log line has status=interrupted'
else
  echo 'FAIL: no status=interrupted in the last log line'
  fail=1
fi
exit "${fail}"
