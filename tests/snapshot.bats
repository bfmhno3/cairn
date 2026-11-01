#!/usr/bin/env bats
# snapshot: names, hard links, dry run, exclusions, rsync failures and the
# helpers of lib/cairn/snapshot.sh tested by sourcing them.

# shellcheck disable=SC2153

load test_helper

NAME=20261031T090000Z

@test "snapshot prints the name and writes snapshot, manifest and latest" {
  CAIRN_NOW="${NAME}" run --separate-stderr "${CAIRN}" snapshot
  assert_success
  assert_output "${NAME}"
  assert_regex "${stderr}" \
    '^cairn: snapshot 20261031T090000Z: 8 files, 49 bytes transferred in [0-9]+ s$'
  assert_file_exist "${REPO}/snapshots/${NAME}${SRC}/plain.txt"
  assert_file_exist "${REPO}/manifests/${NAME}.sha256"
  assert_equal "$(readlink -- "${REPO}/latest")" "snapshots/${NAME}"
  assert_not_exist "${REPO}/latest.tmp"
}

@test "snapshot appends one INFO line to the log" {
  make_snapshots "${NAME}"
  run cat "${REPO}/logs/cairn.log"
  assert_success
  assert_regex "${output}" \
    "^[0-9T:+-]+ INFO snapshot name=${NAME} status=ok files=8 bytes=49 seconds=[0-9]+\$"
}

@test "the manifest lists every regular file, hashed correctly" {
  make_snapshots "${NAME}"
  run wc -l <"${REPO}/manifests/${NAME}.sha256"
  assert_output 8
  local sum
  sum="$(sha256sum <"${SRC}/plain.txt")"
  run grep -F "${sum%% *}" "${REPO}/manifests/${NAME}.sha256"
  assert_success
  assert_output --partial "plain.txt"
}

@test "a second snapshot hard-links unchanged files to the first" {
  make_snapshots 20261031T090000Z 20261031T100000Z
  local first second
  first="$(stat -c %i "${REPO}/snapshots/20261031T090000Z${SRC}/plain.txt")"
  second="$(stat -c %i "${REPO}/snapshots/20261031T100000Z${SRC}/plain.txt")"
  assert_equal "${first}" "${second}"
  assert_equal "$(readlink -- "${REPO}/latest")" \
    'snapshots/20261031T100000Z'
}

@test "a changed file gets its own inode, the old snapshot keeps the data" {
  make_snapshots 20261031T090000Z
  printf 'changed\n' >"${SRC}/plain.txt"
  make_snapshots 20261031T100000Z
  assert_equal "$(<"${REPO}/snapshots/20261031T090000Z${SRC}/plain.txt")" \
    plain
  assert_equal "$(<"${REPO}/snapshots/20261031T100000Z${SRC}/plain.txt")" \
    changed
}

@test "an existing snapshot name: exit 1" {
  make_snapshots "${NAME}"
  CAIRN_NOW="${NAME}" run "${CAIRN}" snapshot
  assert_failure 1
  assert_output "cairn: error: snapshot ${NAME} already exists"
}

@test "a malformed CAIRN_NOW: exit 2" {
  CAIRN_NOW=yesterday run "${CAIRN}" snapshot
  assert_failure 2
  assert_output 'cairn: error: CAIRN_NOW must look like 20261031T090000Z'
  assert_equal "$(snapshot_names)" ''
}

@test "without CAIRN_NOW the name is the current UTC time" {
  run "${CAIRN}" -q snapshot
  assert_success
  assert_regex "${output}" '^[0-9]{8}T[0-9]{6}Z$'
  assert_dir_exist "${REPO}/snapshots/${output}"
}

@test "-n shows the name and changes nothing" {
  CAIRN_NOW="${NAME}" run "${CAIRN}" -n snapshot
  assert_success
  assert_output "would create ${NAME}"
  assert_equal "$(snapshot_names)" ''
  assert_not_exist "${REPO}/latest"
  assert_not_exist "${REPO}/logs/cairn.log"
}

@test "exclude patterns keep files out of the snapshot" {
  write_config 'exclude = *.md' 'exclude = nested'
  make_snapshots "${NAME}"
  assert_file_exist "${REPO}/snapshots/${NAME}${SRC}/plain.txt"
  assert_not_exist "${REPO}/snapshots/${NAME}${SRC}/中文.md"
  assert_not_exist "${REPO}/snapshots/${NAME}${SRC}/nested"
}

@test "stale partial directories are removed with a warning" {
  mkdir -p "${REPO}/snapshots/20261030T090000Z.partial/leftover"
  CAIRN_NOW="${NAME}" run "${CAIRN}" -q snapshot
  assert_success
  assert_line 'cairn: warning: removing stale 20261030T090000Z.partial'
  assert_not_exist "${REPO}/snapshots/20261030T090000Z.partial"
  assert_equal "$(snapshot_names)" "${NAME}"
}

@test "rsync failure: exit 1, no partial, status=failed in the log" {
  write_config
  printf 'repo = %s\nsource = /nonexistent/cairn-test\n' "${REPO}" \
    >"${CAIRN_CONFIG}"
  CAIRN_NOW="${NAME}" run --separate-stderr "${CAIRN}" snapshot
  assert_failure 1
  assert_output ''
  assert_regex "${stderr}" 'cairn: error: rsync failed with exit 23$'
  assert_equal "$(snapshot_names)" ''
  run cat "${REPO}/logs/cairn.log"
  assert_regex "${output}" \
    "ERROR snapshot name=${NAME} status=failed rsync_exit=23\$"
}

@test "rsync exit 24 is a success with a warning" {
  local stub="${BATS_TEST_TMPDIR}/stub"
  mkdir "${stub}"
  # 假 rsync: 建好目标目录, 打印 --stats 的两行, 以 24 退出。
  cat >"${stub}/rsync" <<'STUB'
#!/usr/bin/env bash
mkdir -p -- "${@: -1}"
printf 'Number of files: 3 (reg: 2, dir: 1)\n'
printf 'Total transferred file size: 1,234 bytes\n'
exit 24
STUB
  chmod +x "${stub}/rsync"
  PATH="${stub}:${PATH}" CAIRN_NOW="${NAME}" run --separate-stderr \
    "${CAIRN}" snapshot
  assert_success
  assert_output "${NAME}"
  assert_regex "${stderr}" 'cairn: warning: some files vanished during the snapshot'
  assert_regex "${stderr}" 'cairn: snapshot .*: 2 files, 1234 bytes'
  assert_dir_exist "${REPO}/snapshots/${NAME}"
}

@test "snapshot on a directory that is not a repository: exit 3" {
  rm -- "${REPO}/cairn.repo"
  run "${CAIRN}" snapshot
  assert_failure 3
  assert_output \
    "cairn: error: ${REPO} is not a cairn repository (run 'cairn init ${REPO}')"
}

@test "list on an empty repository prints only the header" {
  run --separate-stderr "${CAIRN}" list
  assert_success
  assert_output 'NAME               FILES     SIZE'
  assert_equal "${stderr}" ''
}

@test "list shows one row per snapshot, oldest first" {
  make_snapshots 20261031T100000Z 20261031T090000Z
  run "${CAIRN}" list
  assert_success
  assert_line -n 0 'NAME               FILES     SIZE'
  assert_line -n 1 --regexp '^20261031T090000Z +8 +[0-9.]+[KMG]?$'
  assert_line -n 2 --regexp '^20261031T100000Z +8 +[0-9.]+[KMG]?$'
}

# --- libraries tested by sourcing them -------------------------------

@test "snapshot::name returns CAIRN_NOW unchanged" {
  source "${CAIRN_ROOT}/lib/cairn/log.sh"
  source "${CAIRN_ROOT}/lib/cairn/snapshot.sh"
  CAIRN_NOW=20300102T030405Z run cairn::snapshot::name
  assert_success
  assert_output 20300102T030405Z
}

@test "snapshot::name rejects a malformed CAIRN_NOW with status 2" {
  source "${CAIRN_ROOT}/lib/cairn/log.sh"
  source "${CAIRN_ROOT}/lib/cairn/snapshot.sh"
  CAIRN_NOW=2030-01-02 run cairn::snapshot::name
  assert_failure 2
  assert_output 'cairn: error: CAIRN_NOW must look like 20261031T090000Z'
}

@test "snapshot::stats reads files and bytes without thousands separators" {
  source "${CAIRN_ROOT}/lib/cairn/log.sh"
  source "${CAIRN_ROOT}/lib/cairn/snapshot.sh"
  local report="${BATS_TEST_TMPDIR}/stats.txt"
  cat >"${report}" <<'STATS'

Number of files: 1,234 (reg: 1,000, dir: 200, link: 34)
Number of created files: 5
Total file size: 9,999 bytes
Total transferred file size: 1,234,567 bytes
STATS
  run cairn::snapshot::stats "${report}"
  assert_success
  assert_output '1000 1234567'
}

@test "snapshot::stats of an empty report is 0 0" {
  source "${CAIRN_ROOT}/lib/cairn/log.sh"
  source "${CAIRN_ROOT}/lib/cairn/snapshot.sh"
  run cairn::snapshot::stats /dev/null
  assert_success
  assert_output '0 0'
}
