#!/usr/bin/env bats
# verify and diff, including paths with spaces (diff.awk parses by
# position, not by fields).

# shellcheck disable=SC2153

load test_helper

A=20261031T090000Z
B=20261031T100000Z

@test "verify checks the latest snapshot by default" {
  make_snapshots "${A}" "${B}"
  run "${CAIRN}" verify
  assert_success
  assert_output "ok ${B} (8 files)"
}

@test "verify NAME checks that snapshot" {
  make_snapshots "${A}" "${B}"
  run "${CAIRN}" verify "${A}"
  assert_success
  assert_output "ok ${A} (8 files)"
}

@test "verify reports a modified file and exits 1" {
  make_snapshots "${A}"
  printf 'tampered\n' >>"${REPO}/snapshots/${A}${SRC}/plain.txt"
  run "${CAIRN}" verify
  assert_failure 1
  assert_line "./${SRC#/}/plain.txt: FAILED"
  assert_line "cairn: error: snapshot ${A} failed verification"
}

@test "verify reports a deleted file" {
  make_snapshots "${A}"
  rm -- "${REPO}/snapshots/${A}${SRC}/plain.txt"
  run "${CAIRN}" verify
  assert_failure 1
  assert_line "cairn: error: snapshot ${A} failed verification"
}

@test "verify of an unknown snapshot: exit 1" {
  make_snapshots "${A}"
  run "${CAIRN}" verify nope
  assert_failure 1
  assert_output 'cairn: error: no snapshot named nope'
}

@test "verify without any snapshot: exit 1" {
  run "${CAIRN}" verify
  assert_failure 1
  assert_output 'cairn: error: no snapshots to verify'
}

@test "verify of a snapshot without manifest: exit 1" {
  make_snapshots "${A}"
  rm -- "${REPO}/manifests/${A}.sha256"
  run "${CAIRN}" verify "${A}"
  assert_failure 1
  assert_output "cairn: error: no manifest for ${A}"
}

@test "diff of identical snapshots is empty and exits 0" {
  make_snapshots "${A}" "${B}"
  run "${CAIRN}" diff "${A}" "${B}"
  assert_success
  assert_output ''
}

@test "diff lists A, D and M sorted by path" {
  make_snapshots "${A}"
  rm -- "${SRC}/.hidden"
  printf 'new\n' >"${SRC}/zz_new.txt"
  printf 'edited\n' >"${SRC}/plain.txt"
  make_snapshots "${B}"
  run "${CAIRN}" diff "${A}" "${B}"
  assert_success
  local base="./${SRC#/}"
  assert_line -n 0 "D ${base}/.hidden"
  assert_line -n 1 "M ${base}/plain.txt"
  assert_line -n 2 "A ${base}/zz_new.txt"
  assert_equal "${#lines[@]}" 3
}

@test "diff handles file names with spaces" {
  make_snapshots "${A}"
  printf 'edited\n' >"${SRC}/with space.txt"
  make_snapshots "${B}"
  run "${CAIRN}" diff "${A}" "${B}"
  assert_success
  assert_output "M ./${SRC#/}/with space.txt"
}

@test "diff of an unknown snapshot: exit 1" {
  make_snapshots "${A}"
  run "${CAIRN}" diff "${A}" nope
  assert_failure 1
  assert_output 'cairn: error: no snapshot named nope'
}

@test "diff needs exactly two names: exit 2" {
  run "${CAIRN}" diff "${A}"
  assert_failure 2
  assert_line -n 0 'cairn: error: usage: cairn diff OLD NEW'
}
