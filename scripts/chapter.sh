#!/usr/bin/env bash
#
# Runs every lab script of one chapter inside a throwaway sandbox.
#
# Usage: scripts/chapter.sh chNN
#
# For each lab/chNN/*.sh (C-locale order) the script is run with the
# sandbox as working directory, and its stdout, stderr and exit status
# are saved under out/chNN/<stem>.{stdout,stderr,status}.
#   *_fail.sh  must exit non-zero, every other lab must exit 0
#   *_host.sh  is skipped when CI=true

set -o nounset
set -o pipefail

CAIRN_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly CAIRN_ROOT

#######################################
# Print an error message to stderr.
# Arguments:
#   Message text.
# Outputs:
#   Writes "chapter.sh: <message>" to stderr.
#######################################
err() {
  printf 'chapter.sh: %s\n' "$*" >&2
}

#######################################
# Run one lab file in a fresh sandbox.
# Globals:
#   CAIRN_ROOT
# Arguments:
#   Chapter name, lab file path relative to the repository root.
# Outputs:
#   Writes out/<chapter>/<stem>.{stdout,stderr,status}.
# Returns:
#   The lab's exit status.
#######################################
run_lab() {
  local chapter="$1"
  local rel="$2"
  local stem="${rel##*/}"
  stem="${stem%.sh}"
  local out_dir="${CAIRN_ROOT}/out/${chapter}"
  local lab_tmp
  lab_tmp="$(mktemp -d "${TMPDIR:-/tmp}/cairn-lab.XXXXXX")" || return 1
  mkdir -p "${out_dir}"

  local status
  (
    cd "${lab_tmp}" || exit 1
    export CAIRN_ROOT
    export LAB_TMP="${lab_tmp}"
    export PATH="${CAIRN_ROOT}/bin:${PATH}"
    if [[ -x "${CAIRN_ROOT}/${rel}" ]]; then
      timeout 300 "${CAIRN_ROOT}/${rel}"
    else
      timeout 300 bash "${CAIRN_ROOT}/${rel}"
    fi
  ) >"${out_dir}/${stem}.stdout" 2>"${out_dir}/${stem}.stderr"
  status=$?
  printf '%d\n' "${status}" >"${out_dir}/${stem}.status"

  chmod -R u+w "${lab_tmp}"
  rm -rf "${lab_tmp}"
  return "${status}"
}

#######################################
# Run all labs of a chapter and report.
# Globals:
#   CAIRN_ROOT, CI
# Arguments:
#   Chapter name such as ch01.
# Returns:
#   0 if every lab behaved as expected, 1 otherwise, 2 on usage error.
#######################################
main() {
  if (($# != 1)) || [[ ! "$1" =~ ^ch[0-9]{2}$ ]]; then
    err "usage: scripts/chapter.sh chNN"
    return 2
  fi
  local chapter="$1"
  local lab_dir="${CAIRN_ROOT}/lab/${chapter}"
  if [[ ! -d "${lab_dir}" ]]; then
    err "no such chapter: ${chapter}"
    return 2
  fi

  local failed=0
  local file rel stem status expected
  while IFS= read -r file; do
    rel="lab/${chapter}/${file}"
    stem="${file%.sh}"
    if [[ "${file}" == *_host.sh && "${CI:-}" == true ]]; then
      printf 'skip %s (host only)\n' "${rel}"
      continue
    fi
    expected=ok
    [[ "${file}" == *_fail.sh ]] && expected=fail
    run_lab "${chapter}" "${rel}"
    status=$?
    if [[ "${expected}" == ok && "${status}" -eq 0 ]] \
      || [[ "${expected}" == fail && "${status}" -ne 0 ]]; then
      printf 'ok   %s\n' "${rel}"
    else
      printf 'FAIL %s (exit %d)\n' "${rel}" "${status}"
      tail -n 20 "${CAIRN_ROOT}/out/${chapter}/${stem}.stderr"
      failed=1
    fi
  done < <(cd "${lab_dir}" && LC_ALL=C find . -maxdepth 1 -name '*.sh' \
    -printf '%f\n' | LC_ALL=C sort)
  return "${failed}"
}

main "$@"
