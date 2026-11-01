#!/usr/bin/env bats
# Command line: options, usage errors, init, exit codes 0 and 2.

load test_helper

@test "--version prints the version" {
  run "${CAIRN}" --version
  assert_success
  assert_output 'cairn 0.1.0'
}

@test "--help prints usage and the exit code table on stdout" {
  run --separate-stderr "${CAIRN}" --help
  assert_success
  assert_line 'Usage: cairn [OPTIONS] COMMAND [ARGS]'
  assert_line 'Exit codes:'
  assert_line --partial '4    another cairn holds the repository lock'
  assert_equal "${stderr}" ''
}

@test "help is the same as --help" {
  run "${CAIRN}" --help
  local expected="${output}"
  run "${CAIRN}" help
  assert_success
  assert_output "${expected}"
}

@test "no arguments: usage on stderr, exit 2" {
  run --separate-stderr "${CAIRN}"
  assert_failure 2
  assert_equal "${output}" ''
  [[ "${stderr}" == 'Usage: cairn '* ]]
}

@test "unknown command: exit 2 with both messages" {
  run "${CAIRN}" frobnicate
  assert_failure 2
  assert_line -n 0 "cairn: error: unknown command 'frobnicate'"
  assert_line -n 1 "cairn: error: run 'cairn --help' for usage"
}

@test "unknown option: exit 2 with both messages" {
  run "${CAIRN}" --frobnicate list
  assert_failure 2
  assert_line -n 0 "cairn: error: unknown option '--frobnicate'"
  assert_line -n 1 "cairn: error: run 'cairn --help' for usage"
}

@test "option without its argument: exit 2" {
  run "${CAIRN}" -c
  assert_failure 2
  assert_line -n 0 "cairn: error: option '-c' requires an argument"
  assert_line -n 1 "cairn: error: run 'cairn --help' for usage"
}

@test "wrong argument count is a usage error for every command" {
  local cmd
  for cmd in 'init' 'init a b' 'diff only-one' 'list extra' \
    'prune extra' 'report extra' 'verify a b'; do
    # 故意不加引号: 要把 $cmd 拆成多个参数。
    # shellcheck disable=SC2086
    run "${CAIRN}" ${cmd}
    assert_failure 2
    assert_line -n 1 "cairn: error: run 'cairn --help' for usage"
  done
}

@test "-c FILE, --config FILE and --config=FILE are equivalent" {
  local other="${BATS_TEST_TMPDIR}/other.conf"
  cp -- "${CAIRN_CONFIG}" "${other}"
  rm -- "${CAIRN_CONFIG}"
  run "${CAIRN}" -c "${other}" list
  assert_success
  assert_output 'NAME               FILES     SIZE'
  run "${CAIRN}" --config "${other}" list
  assert_success
  run "${CAIRN}" --config="${other}" list
  assert_success
}

@test "-- ends the options" {
  run "${CAIRN}" -- list
  assert_success
  run "${CAIRN}" -- --version
  assert_failure 2
  assert_line -n 0 "cairn: error: unknown command '--version'"
}

@test "init creates the repository layout and the config" {
  local dir="${BATS_TEST_TMPDIR}/fresh"
  rm -- "${CAIRN_CONFIG}"
  run "${CAIRN}" init "${dir}"
  assert_success
  assert_output "cairn: wrote ${CAIRN_CONFIG}"
  assert_file_exist "${dir}/cairn.repo"
  assert_equal "$(<"${dir}/cairn.repo")" 'cairn-repo 1'
  assert_dir_exist "${dir}/snapshots"
  assert_dir_exist "${dir}/manifests"
  assert_dir_exist "${dir}/logs"
  run grep -E '^(repo = |keep_last = 5$|keep_daily = 7$|keep_weekly = 4$)' \
    "${CAIRN_CONFIG}"
  assert_line "repo = ${dir}"
  assert_line 'keep_last = 5'
  assert_line 'keep_daily = 7'
  assert_line 'keep_weekly = 4'
}

@test "init on an existing repository is a no-op" {
  run "${CAIRN}" init "${REPO}"
  assert_success
  assert_output "cairn: ${REPO} is already a cairn repository"
}

@test "init does not overwrite an existing config" {
  local before
  before="$(<"${CAIRN_CONFIG}")"
  run "${CAIRN}" init "${BATS_TEST_TMPDIR}/second"
  assert_success
  assert_output ''
  assert_equal "$(<"${CAIRN_CONFIG}")" "${before}"
}

@test "init on a non-empty directory: exit 3" {
  run "${CAIRN}" init "${SRC}"
  assert_failure 3
  assert_output "cairn: error: ${SRC} exists and is not empty"
}

@test "-q silences the informational message of init" {
  rm -- "${CAIRN_CONFIG}"
  run "${CAIRN}" -q init "${BATS_TEST_TMPDIR}/fresh"
  assert_success
  assert_output ''
  assert_file_exist "${CAIRN_CONFIG}"
}

@test "ERR trap names the failed command, -v adds the call frames" {
  [[ "${EUID}" -ne 0 ]] || skip 'root reads files whatever their mode'
  make_snapshots 20261031T090000Z
  chmod 000 "${REPO}/logs/cairn.log"
  run "${CAIRN}" report
  assert_failure
  assert_output --partial 'cairn: error: command failed (exit 2): awk -f'
  refute_output --partial '  at cmd_report ('
  run "${CAIRN}" -v report
  assert_failure
  assert_output --partial '  at cmd_report ('
  assert_output --partial '  at main ('
}
