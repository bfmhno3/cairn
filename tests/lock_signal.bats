#!/usr/bin/env bats
# The repository lock (exit 4) and SIGINT/SIGTERM during a snapshot
# (exit 130/143). No test sleeps for a fixed time: a slow snapshot is
# started, the test waits for a marker (the .partial directory that
# rsync creates), and only then acts.

# shellcheck disable=SC2153

load test_helper

NAME=20261031T090000Z

setup() {
  common_setup
  # 一个 8 MiB 的源目录, 配合 CAIRN_BWLIMIT=256 (KiB/s) 至少要跑 30 秒,
  # 所以信号一定在 rsync 运行期间到达。
  BIG="${BATS_TEST_TMPDIR}/big"
  bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${BIG}" --big 8
  printf 'repo = %s\nsource = %s\n' "${REPO}" "${BIG}" >"${CAIRN_CONFIG}"
  SLOW_PID=''
}

teardown() {
  # 保险: 测试失败时不要留下仍在跑的 cairn。
  if [[ -n "${SLOW_PID}" ]]; then
    kill -KILL "${SLOW_PID}" 2>/dev/null || :
    pkill -KILL -f "rsync .*${BATS_TEST_TMPDIR}" 2>/dev/null || :
  fi
}

#######################################
# Start a slow snapshot in the background and wait until rsync runs.
# Globals:
#   SLOW_PID, REPO, BATS_TEST_TMPDIR
# Outputs:
#   Sets SLOW_PID; the snapshot's stderr goes to $BATS_TEST_TMPDIR/slow.err.
#######################################
start_slow_snapshot() {
  # 后台作业 (没有作业控制时) 和 bats --jobs 下的测试进程都会忽略 SIGINT,
  # 而 bash 无法重新打开已被忽略的信号: 用 env --default-signal 在 exec
  # 之前把 INT 恢复成默认处理, cairn 才能装它的 INT trap。
  CAIRN_BWLIMIT=256 CAIRN_NOW="${NAME}" \
    env --default-signal=INT "${CAIRN}" snapshot \
    >"${BATS_TEST_TMPDIR}/slow.out" 2>"${BATS_TEST_TMPDIR}/slow.err" &
  SLOW_PID=$!
  local tries
  for ((tries = 0; tries < 400; tries++)); do
    if compgen -G "${REPO}/snapshots/*.partial" >/dev/null; then
      return 0
    fi
    sleep 0.05
  done
  echo 'timeout: rsync never created the .partial directory' >&2
  return 1
}

#######################################
# Wait until nobody holds the repository lock.
#
# rsync's helper processes inherit the lock descriptor and may outlive
# cairn by a few milliseconds, so the lock is free slightly after cairn
# exited, not at the very instant.
# Globals:
#   REPO
# Returns:
#   0 once the lock is free, 1 after about 10 s.
#######################################
wait_for_free_lock() {
  local tries fd
  for ((tries = 0; tries < 200; tries++)); do
    exec {fd}>"${REPO}/.lock"
    if flock -n "${fd}"; then
      exec {fd}>&-
      return 0
    fi
    exec {fd}>&-
    sleep 0.05
  done
  return 1
}

@test "a second snapshot while the lock is held: exit 4" {
  exec {held}>"${REPO}/.lock"
  flock -n "${held}"
  run "${CAIRN}" snapshot
  assert_failure 4
  assert_output "cairn: error: another cairn is running on ${REPO}"
  assert_equal "$(snapshot_names)" ''
}

@test "prune while the lock is held: exit 4" {
  exec {held}>"${REPO}/.lock"
  flock -n "${held}"
  run "${CAIRN}" prune
  assert_failure 4
  assert_output "cairn: error: another cairn is running on ${REPO}"
}

@test "snapshot -n also needs the lock" {
  exec {held}>"${REPO}/.lock"
  flock -n "${held}"
  run "${CAIRN}" -n snapshot
  assert_failure 4
}

@test "read-only commands do not take the lock" {
  make_snapshots "${NAME}"
  exec {held}>"${REPO}/.lock"
  flock -n "${held}"
  run "${CAIRN}" list
  assert_success
  run "${CAIRN}" verify
  assert_success
  run "${CAIRN}" report
  assert_success
}

@test "the lock is released when cairn exits" {
  make_snapshots 20261031T090000Z
  run "${CAIRN}" -q prune
  assert_success
  make_snapshots 20261031T100000Z
  assert_equal "$(snapshot_names)" $'20261031T090000Z\n20261031T100000Z'
}

@test "lock::acquire: 0 on a free repository, 4 on a busy one" {
  source "${CAIRN_ROOT}/lib/cairn/log.sh"
  source "${CAIRN_ROOT}/lib/cairn/lock.sh"
  run cairn::lock::acquire "${REPO}"
  assert_success
  # run 在子 shell 里执行, 子 shell 退出时锁已释放; 这次在当前 shell 里拿。
  cairn::lock::acquire "${REPO}"
  run cairn::lock::acquire "${REPO}"
  assert_failure 4
  assert_output "cairn: error: another cairn is running on ${REPO}"
}

@test "lock::acquire: 1 if the lock file cannot be opened" {
  source "${CAIRN_ROOT}/lib/cairn/log.sh"
  source "${CAIRN_ROOT}/lib/cairn/lock.sh"
  run cairn::lock::acquire "${BATS_TEST_TMPDIR}/no/such/dir"
  assert_failure 1
}

@test "a running snapshot holds the lock: the second one exits 4" {
  start_slow_snapshot
  run "${CAIRN}" snapshot
  assert_failure 4
  assert_output "cairn: error: another cairn is running on ${REPO}"
  kill -TERM "${SLOW_PID}"
  wait "${SLOW_PID}" || :
}

@test "SIGINT: exit 130, partial removed, status=interrupted logged" {
  start_slow_snapshot
  kill -INT "${SLOW_PID}"
  local status=0
  wait "${SLOW_PID}" || status=$?
  assert_equal "${status}" 130
  run compgen -G "${REPO}/snapshots/*.partial"
  assert_failure
  assert_equal "$(snapshot_names)" ''
  run tail -n 1 "${REPO}/logs/cairn.log"
  assert_regex "${output}" \
    "WARN snapshot name=${NAME} status=interrupted\$"
  run cat "${BATS_TEST_TMPDIR}/slow.err"
  # rsync 自己也会在 stderr 写几行 "received SIGINT", 只看 cairn 的那一行。
  assert_line "cairn: warning: interrupted, removing ${NAME}.partial"
  assert_equal "$(<"${BATS_TEST_TMPDIR}/slow.out")" ''
}

@test "SIGTERM: exit 143, partial removed, status=interrupted logged" {
  start_slow_snapshot
  kill -TERM "${SLOW_PID}"
  local status=0
  wait "${SLOW_PID}" || status=$?
  assert_equal "${status}" 143
  assert_equal "$(snapshot_names)" ''
  run tail -n 1 "${REPO}/logs/cairn.log"
  assert_regex "${output}" \
    "WARN snapshot name=${NAME} status=interrupted\$"
}

@test "the lock is free again after SIGTERM" {
  start_slow_snapshot
  kill -TERM "${SLOW_PID}"
  wait "${SLOW_PID}" || :
  wait_for_free_lock
  # 锁释放了, 同名的快照可以重新做 (这次不限速)。
  run env -u CAIRN_BWLIMIT CAIRN_NOW="${NAME}" "${CAIRN}" -q snapshot
  assert_success
  assert_output "${NAME}"
}

@test "interrupted snapshots show up in the report" {
  start_slow_snapshot
  kill -INT "${SLOW_PID}"
  wait "${SLOW_PID}" || :
  run "${CAIRN}" report
  assert_success
  assert_line -n 0 'snapshots    1'
  assert_line -n 1 'ok           0'
  assert_line -n 3 'interrupted  1'
}
