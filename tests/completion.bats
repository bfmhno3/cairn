#!/usr/bin/env bats
# completions/cairn.bash: set COMP_WORDS and COMP_CWORD by hand, call
# _cairn and check COMPREPLY. `cairn list` is a stub function in most
# tests and the real command on a test repository in the others; it never
# touches the user's repository.

load test_helper

setup() {
  common_setup
  # shellcheck source=../completions/cairn.bash
  source "${CAIRN_ROOT}/completions/cairn.bash"
  # 文件补全看当前目录: 用一个空的子目录, 不受测试夹具影响。
  mkdir -- "${BATS_TEST_TMPDIR}/work"
  cd -- "${BATS_TEST_TMPDIR}/work" || return
}

#######################################
# Complete the given words as if the cursor were on the last one.
# Arguments:
#   The words of the command line; the last one is the word being
#   completed (may be empty).
# Globals:
#   Sets COMP_WORDS, COMP_CWORD and COMPREPLY.
#######################################
complete_words() {
  COMP_WORDS=("$@")
  COMP_CWORD=$(($# - 1))
  _cairn
}

#######################################
# Define a stand-in for `cairn`: it writes its arguments to the file
# stub_args, then prints a header line and three snapshot rows (or fails
# when STUB_FAIL is set).
#######################################
stub_cairn() {
  cairn() {
    printf '%s\n' "$*" >"${BATS_TEST_TMPDIR}/stub_args"
    if [[ -n "${STUB_FAIL:-}" ]]; then
      return 1
    fi
    printf 'NAME               FILES     SIZE\n'
    printf '%-18s %8s %8s\n' 20261029T090000Z 13 1.2K \
      20261030T090000Z 14 3.0K 20261031T090000Z 14 0
  }
}

#######################################
# Print COMPREPLY sorted, on one line: compgen -f lists files in
# directory order, which the tests must not depend on.
#######################################
sorted_reply() {
  printf '%s\n' "${COMPREPLY[@]}" | LC_ALL=C sort | paste -sd ' '
}

@test "the file registers _cairn for cairn" {
  run complete -p cairn
  assert_success
  assert_output 'complete -F _cairn cairn'
}

@test "first word: a prefix completes to the matching command" {
  complete_words cairn ver
  assert_equal "${COMPREPLY[*]}" verify
}

@test "first word: empty offers every command and option" {
  complete_words cairn ''
  assert_equal "${#COMPREPLY[@]}" 19
  assert_equal "${COMPREPLY[0]}" -c
  assert_equal "${COMPREPLY[-1]}" report
}

@test "first word: a dash offers only options" {
  complete_words cairn --v
  assert_equal "${COMPREPLY[*]}" '--verbose --version'
}

@test "the command word may follow options" {
  complete_words cairn -q -n sna
  assert_equal "${COMPREPLY[*]}" snapshot
}

@test "no match leaves COMPREPLY empty" {
  complete_words cairn zzz
  assert_equal "${#COMPREPLY[@]}" 0
}

@test "after -c: files" {
  touch cairn.conf other.conf notes.txt
  complete_words cairn -c ca
  assert_equal "${COMPREPLY[*]}" cairn.conf
  complete_words cairn --config ''
  assert_equal "$(sorted_reply)" 'cairn.conf notes.txt other.conf'
}

@test "after --config=: files, with and without a typed prefix" {
  touch cairn.conf other.conf
  complete_words cairn --config =
  assert_equal "$(sorted_reply)" 'cairn.conf other.conf'
  complete_words cairn --config = oth
  assert_equal "${COMPREPLY[*]}" other.conf
}

@test "after init: directories only" {
  mkdir subdir
  touch subfile
  complete_words cairn init sub
  assert_equal "${COMPREPLY[*]}" subdir
}

@test "after init REPO: nothing more" {
  mkdir subdir
  complete_words cairn init subdir ''
  assert_equal "${#COMPREPLY[@]}" 0
}

@test "after verify: snapshot names from cairn list, header skipped" {
  stub_cairn
  complete_words cairn verify ''
  assert_equal "${COMPREPLY[*]}" \
    '20261029T090000Z 20261030T090000Z 20261031T090000Z'
  complete_words cairn verify 20261030
  assert_equal "${COMPREPLY[*]}" 20261030T090000Z
}

@test "after diff: two names, then nothing" {
  stub_cairn
  complete_words cairn diff 20261029T090000Z 20261031
  assert_equal "${COMPREPLY[*]}" 20261031T090000Z
  complete_words cairn diff 20261029T090000Z 20261031T090000Z ''
  assert_equal "${#COMPREPLY[@]}" 0
}

@test "-c FILE before the command is passed on to cairn list" {
  stub_cairn
  complete_words cairn -c my.conf verify ''
  assert_equal "$(<"${BATS_TEST_TMPDIR}/stub_args")" '-c my.conf list'
  complete_words cairn --config = my2.conf verify ''
  assert_equal "$(<"${BATS_TEST_TMPDIR}/stub_args")" '-c my2.conf list'
}

@test "cairn list failing leaves COMPREPLY empty" {
  stub_cairn
  STUB_FAIL=1
  complete_words cairn verify ''
  assert_equal "${#COMPREPLY[@]}" 0
}

@test "commands without arguments complete nothing" {
  stub_cairn
  complete_words cairn list ''
  assert_equal "${#COMPREPLY[@]}" 0
  complete_words cairn prune ''
  assert_equal "${#COMPREPLY[@]}" 0
}

@test "verify against the real cairn list on a test repository" {
  make_snapshots 20261029T090000Z 20261030T090000Z
  complete_words cairn verify ''
  assert_equal "${COMPREPLY[*]}" '20261029T090000Z 20261030T090000Z'
}

@test "an empty repository has no names to offer" {
  complete_words cairn diff ''
  assert_equal "${#COMPREPLY[@]}" 0
}
