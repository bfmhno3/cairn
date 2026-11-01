# shellcheck shell=bash
# Shared setup for the cairn bats suite: load it with `load test_helper`.
#
# Every test runs in its own $BATS_TEST_TMPDIR, with HOME and the config
# search path pointing into it, so no test touches the real home or sees
# the settings of another test (this is what makes `bats --jobs` safe).

# run 的 --separate-stderr 等选项要 bats 1.5.0 以上。
bats_require_minimum_version 1.5.0

bats_load_library bats-support
bats_load_library bats-assert
bats_load_library bats-file

CAIRN_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
CAIRN="${CAIRN_ROOT}/bin/cairn"
export CAIRN_ROOT

#######################################
# Write the test's config file: repo, one source, retention keys.
# Globals:
#   CAIRN_CONFIG, REPO, SRC
# Arguments:
#   Extra config lines, one per argument (appended as given).
#######################################
# 参数只在测试文件里使用, 这里的 setup 不传, 所以关掉这两条提示。
# shellcheck disable=SC2119,SC2120
write_config() {
  mkdir -p -- "$(dirname -- "${CAIRN_CONFIG}")"
  {
    printf 'repo = %s\n' "${REPO}"
    printf 'source = %s\n' "${SRC}"
    (($# == 0)) || printf '%s\n' "$@"
  } >"${CAIRN_CONFIG}"
}

#######################################
# Isolate the environment, then build a source tree, a repository and
# a config with that one source.
# Globals:
#   BATS_TEST_TMPDIR, CAIRN_ROOT
#   Sets HOME, XDG_CONFIG_HOME, CAIRN_CONFIG, SRC, REPO and PATH.
#######################################
common_setup() {
  HOME="${BATS_TEST_TMPDIR}/home"
  XDG_CONFIG_HOME="${HOME}/.config"
  CAIRN_CONFIG="${XDG_CONFIG_HOME}/cairn/cairn.conf"
  SRC="${BATS_TEST_TMPDIR}/src"
  REPO="${BATS_TEST_TMPDIR}/repo"
  export HOME XDG_CONFIG_HOME CAIRN_CONFIG
  # 外部环境里的 CAIRN_* 不能漏进测试: 每个测试自己设需要的变量。
  unset CAIRN_NOW CAIRN_BWLIMIT CAIRN_JOBS CAIRN_LIB CAIRN_QUIET \
    CAIRN_VERBOSE
  PATH="${CAIRN_ROOT}/bin:${PATH}"
  mkdir -p -- "${HOME}"
  bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${SRC}"
  "${CAIRN}" -q init "${REPO}"
  write_config
}

setup() {
  common_setup
}

#######################################
# Create snapshots, one per name, with CAIRN_NOW set to each name.
# Arguments:
#   Snapshot names (20261031T090000Z form).
#######################################
make_snapshots() {
  local name
  for name in "$@"; do
    CAIRN_NOW="${name}" "${CAIRN}" -q snapshot >/dev/null || return
  done
}

#######################################
# Print the sorted snapshot directory names of $REPO.
#######################################
snapshot_names() {
  find "${REPO}/snapshots" -mindepth 1 -maxdepth 1 -printf '%f\n' \
    | LC_ALL=C sort
}
