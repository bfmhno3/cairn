#!/usr/bin/env bats
# install.sh: run it under five shells into a temporary prefix and check
# what lands where, the modes, that the installed cairn runs, and that
# --uninstall leaves nothing behind. Every test works in its own
# $BATS_TEST_TMPDIR with HOME pointing into it; nothing touches the real
# home directory or ~/.local.

load test_helper

setup() {
  HOME="${BATS_TEST_TMPDIR}/home"
  PREFIX_DIR="${BATS_TEST_TMPDIR}/prefix"
  INSTALL="${CAIRN_ROOT}/install.sh"
  export HOME
  unset DESTDIR CAIRN_LIB CAIRN_CONFIG
  mkdir -p -- "${HOME}"
}

#######################################
# Run install.sh under a shell, with the temporary prefix.
# Globals:
#   INSTALL, PREFIX_DIR
# Arguments:
#   The shell command (one word per argument), then install.sh options
#   after a literal "--"; without "--" the options are --prefix only.
#######################################
run_installer() {
  local shell_cmd=()
  while (($# > 0)) && [[ "$1" != -- ]]; do
    shell_cmd+=("$1")
    shift
  done
  shift
  run --separate-stderr "${shell_cmd[@]}" "${INSTALL}" "$@"
}

#######################################
# Check that a prefix holds exactly the files install.sh promises, with
# the promised modes, and that the installed cairn reports its version.
# Arguments:
#   The prefix directory.
#######################################
assert_installed() {
  local prefix="$1"
  local f name
  assert_file_executable "${prefix}/bin/cairn"
  assert_equal "$(stat -c %a "${prefix}/bin/cairn")" 755
  for f in "${CAIRN_ROOT}"/lib/cairn/*; do
    name="${f##*/}"
    assert_file_exist "${prefix}/lib/cairn/${name}"
    assert_equal "$(stat -c %a "${prefix}/lib/cairn/${name}")" 644
  done
  assert_file_exist \
    "${prefix}/share/bash-completion/completions/cairn"
  assert_equal "$(stat -c %a \
    "${prefix}/share/bash-completion/completions/cairn")" 644
  for f in "${CAIRN_ROOT}"/contrib/systemd/*; do
    name="${f##*/}"
    assert_file_exist "${prefix}/share/cairn/systemd/${name}"
    assert_equal "$(stat -c %a "${prefix}/share/cairn/systemd/${name}")" 644
  done
  run "${prefix}/bin/cairn" --version
  assert_success
  assert_output 'cairn 0.1.0'
}

#######################################
# Count the regular files below a directory.
# Arguments:
#   The directory.
#######################################
count_files() {
  find "$1" -type f | wc -l
}

@test "dash: installs the files with the right modes" {
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  assert_installed "${PREFIX_DIR}"
}

@test "busybox sh: installs the files with the right modes" {
  run_installer "${CAIRN_BUSYBOX}" sh -- --prefix "${PREFIX_DIR}"
  assert_success
  assert_installed "${PREFIX_DIR}"
}

@test "yash: installs the files with the right modes" {
  run_installer yash -- --prefix "${PREFIX_DIR}"
  assert_success
  assert_installed "${PREFIX_DIR}"
}

@test "mksh: installs the files with the right modes" {
  run_installer mksh -- --prefix "${PREFIX_DIR}"
  assert_success
  assert_installed "${PREFIX_DIR}"
}

@test "bash --posix: installs the files with the right modes" {
  run_installer bash --posix -- --prefix "${PREFIX_DIR}"
  assert_success
  assert_installed "${PREFIX_DIR}"
}

@test "installed file set matches the repository" {
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  local expected
  expected=$(($(find "${CAIRN_ROOT}/lib/cairn" -type f | wc -l) + \
  $(find "${CAIRN_ROOT}/contrib/systemd" -type f | wc -l) + 2))
  assert_equal "$(count_files "${PREFIX_DIR}")" "${expected}"
}

@test "install prints one 'installed' line per file" {
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  assert_equal "${#lines[@]}" "$(count_files "${PREFIX_DIR}")"
  assert_line "installed ${PREFIX_DIR}/bin/cairn"
}

@test "default prefix is \$HOME/.local" {
  run_installer dash --
  assert_success
  assert_installed "${HOME}/.local"
}

@test "a prefix with spaces and a trailing slash works" {
  local prefix="${BATS_TEST_TMPDIR}/my prefix"
  run_installer dash -- --prefix "${prefix}/"
  assert_success
  assert_output --partial "installed ${prefix}/bin/cairn"
  assert_installed "${prefix}"
}

@test "installing twice is fine" {
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  assert_installed "${PREFIX_DIR}"
}

@test "DESTDIR is prepended to the prefix" {
  local dest="${BATS_TEST_TMPDIR}/stage"
  DESTDIR="${dest}" run_installer dash -- --prefix /opt/cairn-test
  assert_success
  assert_installed "${dest}/opt/cairn-test"
  assert_not_exist /opt/cairn-test
}

@test "DESTDIR with a trailing slash does not double the slash" {
  local dest="${BATS_TEST_TMPDIR}/stage"
  DESTDIR="${dest}/" run_installer dash -- --prefix /usr
  assert_success
  assert_line "installed ${dest}/usr/bin/cairn"
}

@test "the installed cairn runs a command, not only --version" {
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  local conf="${BATS_TEST_TMPDIR}/cairn.conf"
  run "${PREFIX_DIR}/bin/cairn" -c "${conf}" init "${BATS_TEST_TMPDIR}/repo"
  assert_success
  assert_file_exist "${BATS_TEST_TMPDIR}/repo/cairn.repo"
}

@test "a symlink to the installed cairn finds its libraries" {
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  ln -s "${PREFIX_DIR}/bin/cairn" "${BATS_TEST_TMPDIR}/cairn-link"
  run "${BATS_TEST_TMPDIR}/cairn-link" --version
  assert_success
  assert_output 'cairn 0.1.0'
}

@test "uninstall leaves no files and no directories" {
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  run_installer dash -- --prefix "${PREFIX_DIR}" --uninstall
  assert_success
  assert_equal "$(count_files "${PREFIX_DIR}")" 0
  assert_equal "$(find "${PREFIX_DIR}" -mindepth 1 | wc -l)" 0
}

@test "uninstall prints one 'removed' line per file" {
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  local n
  n="$(count_files "${PREFIX_DIR}")"
  run_installer dash -- --prefix "${PREFIX_DIR}" --uninstall
  assert_success
  assert_equal "${#lines[@]}" "${n}"
  assert_line "removed ${PREFIX_DIR}/bin/cairn"
}

@test "uninstall works under the other shells too" {
  local shell_name
  for shell_name in yash mksh; do
    run_installer "${shell_name}" -- --prefix "${PREFIX_DIR}"
    assert_success
    run_installer "${shell_name}" -- --prefix "${PREFIX_DIR}" --uninstall
    assert_success
    assert_equal "$(find "${PREFIX_DIR}" -mindepth 1 | wc -l)" 0
  done
  run_installer "${CAIRN_BUSYBOX}" sh -- --prefix "${PREFIX_DIR}"
  assert_success
  run_installer "${CAIRN_BUSYBOX}" sh -- --prefix "${PREFIX_DIR}" --uninstall
  assert_success
  assert_equal "$(find "${PREFIX_DIR}" -mindepth 1 | wc -l)" 0
}

@test "uninstall keeps files and directories it did not install" {
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  echo mine >"${PREFIX_DIR}/bin/other-tool"
  echo mine >"${PREFIX_DIR}/lib/cairn/local-note"
  run_installer dash -- --prefix "${PREFIX_DIR}" --uninstall
  assert_success
  assert_file_exist "${PREFIX_DIR}/bin/other-tool"
  assert_file_exist "${PREFIX_DIR}/lib/cairn/local-note"
  assert_file_not_exist "${PREFIX_DIR}/bin/cairn"
  assert_file_not_exist "${PREFIX_DIR}/lib/cairn/log.sh"
  assert_equal "$(count_files "${PREFIX_DIR}")" 2
}

@test "uninstall with nothing installed succeeds quietly" {
  run_installer dash -- --prefix "${PREFIX_DIR}" --uninstall
  assert_success
  assert_output ''
}

@test "uninstall honors DESTDIR" {
  local dest="${BATS_TEST_TMPDIR}/stage"
  DESTDIR="${dest}" run_installer dash -- --prefix /usr
  assert_success
  DESTDIR="${dest}" run_installer dash -- --prefix /usr --uninstall
  assert_success
  assert_equal "$(count_files "${dest}")" 0
  assert_equal "$(find "${dest}/usr" -mindepth 1 | wc -l)" 0
}

@test "-h prints usage to stdout and installs nothing" {
  run_installer dash -- -h --prefix "${PREFIX_DIR}"
  assert_success
  assert_line --index 0 'Usage: install.sh [--prefix DIR] [--uninstall] [-h]'
  assert_not_exist "${PREFIX_DIR}"
}

@test "an unknown option is a usage error, exit 2" {
  run_installer dash -- --bogus
  assert_failure 2
  assert_equal "${stderr_lines[0]}" "install.sh: error: unknown option '--bogus'"
  assert_equal "${stderr_lines[1]}" \
    "install.sh: error: run 'install.sh -h' for usage"
}

@test "--prefix without a value is a usage error, exit 2" {
  run_installer dash -- --prefix
  assert_failure 2
  assert_equal "${stderr_lines[0]}" \
    'install.sh: error: --prefix needs a directory'
}

@test "--prefix with an empty value is a usage error, exit 2" {
  run_installer dash -- --prefix ''
  assert_failure 2
}

@test "a usage error installs nothing" {
  run_installer dash -- --prefix "${PREFIX_DIR}" --bogus
  assert_failure 2
  assert_not_exist "${PREFIX_DIR}"
}

@test "warns, but still installs, when bash is not in PATH" {
  # PATH 里只放安装脚本用得到的外部命令, 没有 bash。
  local bin="${BATS_TEST_TMPDIR}/nobash" tool
  mkdir -- "${bin}"
  for tool in cp mkdir chmod rm rmdir; do
    ln -s "$(command -v "${tool}")" "${bin}/${tool}"
  done
  PATH="${bin}" run_installer "$(command -v dash)" -- --prefix "${PREFIX_DIR}"
  assert_success
  assert_equal "${stderr}" \
    'install.sh: warning: bash not found in PATH; cairn needs bash'
  assert_file_exist "${PREFIX_DIR}/bin/cairn"
}

@test "no warning when bash is in PATH" {
  run_installer dash -- --prefix "${PREFIX_DIR}"
  assert_success
  assert_equal "${stderr}" ''
}

@test "install.sh starts with #!/bin/sh and passes dash -n" {
  run head -n 1 "${INSTALL}"
  assert_output '#!/bin/sh'
  run dash -n "${INSTALL}"
  assert_success
}

@test "checkbashisms finds nothing in install.sh" {
  run checkbashisms "${INSTALL}"
  assert_success
  assert_output ''
}

@test "shellcheck -s sh finds nothing in install.sh" {
  run shellcheck -s sh "${INSTALL}"
  assert_success
  assert_output ''
}
