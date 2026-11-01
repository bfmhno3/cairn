# shellcheck shell=bash
# Shows: cairn report on a log of 30 snapshots over 10 days (CAIRN_NOW
# gives each a fixed name) plus one snapshot that fails because a
# source was removed before the run (rsync exit 23). Exits 1 if the
# counters are not 31 / 30 / 1. The seconds line is timing and varies.
src="${LAB_TMP}/src"
gone="${LAB_TMP}/gone"
repo="${LAB_TMP}/repo"
conf="${LAB_TMP}/cairn.conf"
bad_conf="${LAB_TMP}/bad.conf"
mkdir "${src}" "${gone}" || exit 1
cairn -c "${conf}" init "${repo}" 2>/dev/null || exit 1
printf 'source = %s\n' "${src}" >>"${conf}"
cp "${conf}" "${bad_conf}"
printf 'source = %s\n' "${gone}" >>"${bad_conf}"
rmdir "${gone}" || exit 1

n=0
for day in 20 21 22 23 24 25 26 27 28 29; do
  for hour in 09 13 17; do
    n=$((n + 1))
    # 每个快照新增一个文件, 大小随 n 增长, 字节数因此可预期。
    head -c "$((n * 1000))" /dev/zero >"${src}/file_${n}.dat"
    CAIRN_NOW="202610${day}T${hour}0000Z" \
      cairn -q -c "${conf}" snapshot >/dev/null || exit 1
  done
  if [[ "${day}" == 24 ]]; then
    CAIRN_NOW="20261024T200000Z" \
      cairn -q -c "${bad_conf}" snapshot >/dev/null 2>&1
    echo "failed snapshot attempt exit status: $?"
  fi
done

echo '--- the log: snapshot lines, and the failure ---'
grep -c ' snapshot ' "${repo}/logs/cairn.log"
grep ' ERROR ' "${repo}/logs/cairn.log" | cut -d' ' -f2-
echo '--- cairn report ---'
cairn -c "${conf}" report | tee report.out
grep -qx 'snapshots    31' report.out || exit 1
grep -qx 'ok           30' report.out || exit 1
grep -qx 'failed       1' report.out || exit 1
echo '--- cairn report on an empty repository ---'
cairn -c "${LAB_TMP}/empty.conf" init "${LAB_TMP}/empty" 2>/dev/null \
  || exit 1
printf 'source = %s\n' "${src}" >>"${LAB_TMP}/empty.conf"
cairn -c "${LAB_TMP}/empty.conf" report
