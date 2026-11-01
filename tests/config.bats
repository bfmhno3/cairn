#!/usr/bin/env bats
# Config file: path precedence, parsing rules and every config error
# (exit 3).

load test_helper

@test "no config file: exit 3 and the hint" {
  rm -- "${CAIRN_CONFIG}"
  run "${CAIRN}" list
  assert_failure 3
  assert_output \
    "cairn: error: no config file at ${CAIRN_CONFIG} (run 'cairn init REPO' first)"
}

@test "line without '=': expected 'key = value'" {
  write_config 'keep_last 3'
  run "${CAIRN}" list
  assert_failure 3
  assert_output "cairn: error: ${CAIRN_CONFIG}:3: expected 'key = value'"
}

@test "unknown key" {
  write_config 'colour = blue'
  run "${CAIRN}" list
  assert_failure 3
  assert_output "cairn: error: ${CAIRN_CONFIG}:3: unknown key 'colour'"
}

@test "relative source" {
  write_config 'source = relative/dir'
  run "${CAIRN}" list
  assert_failure 3
  assert_output \
    "cairn: error: ${CAIRN_CONFIG}:3: source must be an absolute path"
}

@test "retention keys must be non-negative integers" {
  local key
  for key in keep_last keep_daily keep_weekly; do
    write_config "${key} = many"
    run "${CAIRN}" list
    assert_failure 3
    assert_output \
      "cairn: error: ${CAIRN_CONFIG}:3: ${key} must be a non-negative integer"
  done
  write_config 'keep_daily = -1'
  run "${CAIRN}" list
  assert_failure 3
}

@test "keep_last must be at least 1" {
  write_config 'keep_last = 0'
  run "${CAIRN}" list
  assert_failure 3
  assert_output "cairn: error: ${CAIRN_CONFIG}: keep_last must be at least 1"
}

@test "repo is required" {
  printf 'source = %s\n' "${SRC}" >"${CAIRN_CONFIG}"
  run "${CAIRN}" list
  assert_failure 3
  assert_output "cairn: error: ${CAIRN_CONFIG}: missing required key 'repo'"
}

@test "source is required" {
  printf 'repo = %s\n' "${REPO}" >"${CAIRN_CONFIG}"
  run "${CAIRN}" list
  assert_failure 3
  assert_output \
    "cairn: error: ${CAIRN_CONFIG}: missing required key 'source'"
}

@test "repo given twice" {
  write_config "repo = ${REPO}"
  run "${CAIRN}" list
  assert_failure 3
  assert_output \
    "cairn: error: ${CAIRN_CONFIG}:3: repo given more than once"
}

@test "a directory without the marker is not a repository" {
  local dir="${BATS_TEST_TMPDIR}/plain_dir"
  mkdir "${dir}"
  printf 'repo = %s\nsource = %s\n' "${dir}" "${SRC}" >"${CAIRN_CONFIG}"
  run "${CAIRN}" list
  assert_failure 3
  assert_output \
    "cairn: error: ${dir} is not a cairn repository (run 'cairn init ${dir}')"
}

@test "comments, blank lines and blanks around '=' are accepted" {
  {
    printf '\n   # a comment\n'
    printf 'repo=%s\n' "${REPO}"
    printf '  source   =   %s  \n' "${SRC}"
    printf 'keep_last =2\n'
  } >"${CAIRN_CONFIG}"
  run "${CAIRN}" list
  assert_success
  assert_output 'NAME               FILES     SIZE'
}

@test "path precedence: -c beats CAIRN_CONFIG beats XDG_CONFIG_HOME" {
  local env_conf="${BATS_TEST_TMPDIR}/env.conf"
  local opt_conf="${BATS_TEST_TMPDIR}/opt.conf"
  # XDG: 空文件, 缺 repo; 环境变量指向的文件缺 source; -c 的文件完整。
  cp -- "${CAIRN_CONFIG}" "${opt_conf}"
  printf 'repo = %s\n' "${REPO}" >"${env_conf}"
  : >"${XDG_CONFIG_HOME}/cairn/cairn.conf"

  unset CAIRN_CONFIG
  run "${CAIRN}" list
  assert_failure 3
  assert_output \
    "cairn: error: ${XDG_CONFIG_HOME}/cairn/cairn.conf: missing required key 'repo'"

  CAIRN_CONFIG="${env_conf}" run "${CAIRN}" list
  assert_failure 3
  assert_output "cairn: error: ${env_conf}: missing required key 'source'"

  CAIRN_CONFIG="${env_conf}" run "${CAIRN}" -c "${opt_conf}" list
  assert_success
}

@test "XDG_CONFIG_HOME falls back to HOME/.config" {
  rm -- "${CAIRN_CONFIG}"
  unset CAIRN_CONFIG XDG_CONFIG_HOME
  run "${CAIRN}" list
  assert_failure 3
  assert_output --partial \
    "no config file at ${HOME}/.config/cairn/cairn.conf"
}

@test "a leading ~/ in a value becomes HOME/" {
  mkdir -p -- "${HOME}/docs"
  printf 'hello\n' >"${HOME}/docs/note.txt"
  printf 'repo = ~/backup\nsource = ~/docs\n' >"${CAIRN_CONFIG}"
  run "${CAIRN}" init "${HOME}/backup"
  assert_success
  CAIRN_NOW=20261031T090000Z run "${CAIRN}" -q snapshot
  assert_success
  assert_file_exist \
    "${HOME}/backup/snapshots/20261031T090000Z${HOME}/docs/note.txt"
}
