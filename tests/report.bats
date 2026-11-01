#!/usr/bin/env bats
# report: the exact output format, on an empty log and on a log with
# several days, failures and interruptions.

# shellcheck disable=SC2153

load test_helper

@test "report on a missing log: zeros, no day rows" {
  run "${CAIRN}" report
  assert_success
  assert_output - <<'EXPECTED'
snapshots    0
ok           0
failed       0
interrupted  0
bytes        0
seconds      avg 0.0 max 0

DAY         SNAPSHOTS  BYTES
EXPECTED
}

@test "report on an empty log is the same as on a missing one" {
  run "${CAIRN}" report
  local expected="${output}"
  : >"${REPO}/logs/cairn.log"
  run "${CAIRN}" report
  assert_success
  assert_output "${expected}"
}

@test "report counts real snapshots per day" {
  make_snapshots 20261030T090000Z 20261031T090000Z 20261031T100000Z
  run "${CAIRN}" report
  assert_success
  assert_line -n 0 'snapshots    3'
  assert_line -n 1 'ok           3'
  assert_line -n 2 'failed       0'
  assert_line -n 3 'interrupted  0'
  # 后两个快照全部硬链接到第一个, 传输的字节数是 0。
  assert_line -n 4 'bytes        49'
  assert_line -n 5 'seconds      avg 0.0 max 0'
  # bats 的 lines 不含空行, 所以表头是第 6 行而不是第 7 行。
  assert_line -n 6 'DAY         SNAPSHOTS  BYTES'
  assert_line -n 7 --regexp '^2026-10-30 +1 +49$'
  assert_line -n 8 --regexp '^2026-10-31 +2 +0$'
}

@test "report counts ok, failed and interrupted lines from the log" {
  cat >"${REPO}/logs/cairn.log" <<'LOG'
2026-10-31T09:00:00+0000 INFO snapshot name=20261031T090000Z status=ok files=10 bytes=2048 seconds=4
2026-10-31T10:00:00+0000 ERROR snapshot name=20261031T100000Z status=failed rsync_exit=23
2026-10-31T11:00:00+0000 WARN snapshot name=20261031T110000Z status=interrupted
2026-11-01T09:00:00+0000 INFO snapshot name=20261101T090000Z status=ok files=10 bytes=1048576 seconds=1
LOG
  run "${CAIRN}" report
  assert_success
  assert_line -n 0 'snapshots    4'
  assert_line -n 1 'ok           2'
  assert_line -n 2 'failed       1'
  assert_line -n 3 'interrupted  1'
  assert_line -n 4 'bytes        1.1M'
  assert_line -n 5 'seconds      avg 2.5 max 4'
}

@test "report rows are sorted by day, oldest first" {
  cat >"${REPO}/logs/cairn.log" <<'LOG'
2026-11-01T09:00:00+0000 INFO snapshot name=20261101T090000Z status=ok files=1 bytes=10 seconds=0
2026-10-29T09:00:00+0000 INFO snapshot name=20261029T090000Z status=ok files=1 bytes=10 seconds=0
LOG
  run "${CAIRN}" report
  assert_success
  assert_line -n 7 --regexp '^2026-10-29 '
  assert_line -n 8 --regexp '^2026-11-01 '
}
