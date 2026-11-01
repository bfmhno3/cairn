#!/usr/bin/env bats
# prune: the pure policy function (sourced) and the command on a real
# repository.

# shellcheck disable=SC2153

load test_helper

setup() {
  common_setup
  source "${CAIRN_ROOT}/lib/cairn/log.sh"
  source "${CAIRN_ROOT}/lib/cairn/prune.sh"
}

@test "select keeps the newest KEEP_LAST and removes the rest" {
  run cairn::prune::select 2 0 0 \
    20261029T090000Z 20261030T090000Z 20261031T090000Z 20261101T090000Z
  assert_success
  assert_line -n 0 'keep 20261101T090000Z last'
  assert_line -n 1 'keep 20261031T090000Z last'
  assert_line -n 2 'remove 20261030T090000Z'
  assert_line -n 3 'remove 20261029T090000Z'
  assert_equal "${#lines[@]}" 4
}

@test "select keeps one snapshot per day as daily" {
  run cairn::prune::select 1 2 0 \
    20261029T090000Z 20261030T090000Z 20261030T100000Z 20261031T090000Z
  assert_success
  assert_line -n 0 'keep 20261031T090000Z last'
  assert_line -n 1 'keep 20261030T100000Z daily'
  assert_line -n 2 'remove 20261030T090000Z'
  assert_line -n 3 'keep 20261029T090000Z daily'
}

@test "select keeps one snapshot per ISO week as weekly" {
  run cairn::prune::select 1 0 2 \
    20261012T090000Z 20261019T090000Z 20261020T090000Z \
    20261027T090000Z 20261029T090000Z
  assert_success
  assert_line -n 0 'keep 20261029T090000Z last'
  assert_line -n 1 'remove 20261027T090000Z'
  assert_line -n 2 'keep 20261020T090000Z weekly'
  assert_line -n 3 'remove 20261019T090000Z'
  assert_line -n 4 'keep 20261012T090000Z weekly'
}

@test "select: a snapshot kept as last still marks its day as seen" {
  run cairn::prune::select 1 5 0 20261031T090000Z 20261031T100000Z
  assert_success
  assert_line -n 0 'keep 20261031T100000Z last'
  assert_line -n 1 'remove 20261031T090000Z'
}

@test "select without names prints nothing" {
  run cairn::prune::select 5 7 4
  assert_success
  assert_output ''
}

@test "select fails on a name that is not a timestamp" {
  run cairn::prune::select 1 0 1 not-a-timestamp
  assert_failure 1
}

@test "week: ISO week of a snapshot name" {
  run cairn::prune::week 20261031T090000Z
  assert_output '2026-W44'
  run cairn::prune::week 20261228T090000Z
  assert_output '2026-W53'
  run cairn::prune::week 20270101T090000Z
  assert_output '2026-W53'
}

@test "prune removes old snapshots and their manifests, newest first" {
  write_config 'keep_last = 2' 'keep_daily = 0' 'keep_weekly = 0'
  make_snapshots 20261028T090000Z 20261029T090000Z 20261030T090000Z \
    20261031T090000Z
  run "${CAIRN}" prune
  assert_success
  assert_line -n 0 'removed 20261029T090000Z'
  assert_line -n 1 'removed 20261028T090000Z'
  assert_equal "${#lines[@]}" 2
  assert_equal "$(snapshot_names)" $'20261030T090000Z\n20261031T090000Z'
  assert_not_exist "${REPO}/manifests/20261028T090000Z.sha256"
  assert_not_exist "${REPO}/manifests/20261029T090000Z.sha256"
  assert_file_exist "${REPO}/manifests/20261030T090000Z.sha256"
}

@test "prune -n lists what it would remove and deletes nothing" {
  write_config 'keep_last = 1' 'keep_daily = 0' 'keep_weekly = 0'
  make_snapshots 20261030T090000Z 20261031T090000Z
  run "${CAIRN}" -n prune
  assert_success
  assert_output 'would remove 20261030T090000Z'
  assert_dir_exist "${REPO}/snapshots/20261030T090000Z"
  assert_file_exist "${REPO}/manifests/20261030T090000Z.sha256"
}

@test "prune -v also reports what it keeps and why" {
  write_config 'keep_last = 1' 'keep_daily = 1' 'keep_weekly = 0'
  make_snapshots 20261029T090000Z 20261030T090000Z 20261031T090000Z
  run "${CAIRN}" -n -v prune
  assert_success
  assert_line -n 0 'keep 20261031T090000Z (last)'
  assert_line -n 1 'keep 20261030T090000Z (daily)'
  assert_line -n 2 'would remove 20261029T090000Z'
}

@test "prune on an empty repository does nothing" {
  run "${CAIRN}" prune
  assert_success
  assert_output ''
}

@test "prune never damages the snapshots it keeps (hard links)" {
  write_config 'keep_last = 1' 'keep_daily = 0' 'keep_weekly = 0'
  make_snapshots 20261030T090000Z 20261031T090000Z
  run "${CAIRN}" prune
  assert_success
  run "${CAIRN}" verify
  assert_success
  assert_output 'ok 20261031T090000Z (8 files)'
}

@test "prune does not touch the repository outside snapshots and manifests" {
  write_config 'keep_last = 1' 'keep_daily = 0' 'keep_weekly = 0'
  make_snapshots 20261030T090000Z 20261031T090000Z
  "${CAIRN}" prune >/dev/null
  assert_file_exist "${REPO}/cairn.repo"
  assert_file_exist "${REPO}/logs/cairn.log"
  assert_equal "$(readlink -- "${REPO}/latest")" \
    'snapshots/20261031T090000Z'
}
