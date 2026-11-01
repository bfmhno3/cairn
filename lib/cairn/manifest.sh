# shellcheck shell=bash
# Manifest helpers for cairn. Library: sourced by bin/cairn, not executed.
#
# A manifest is manifests/<name>.sha256: one sha256sum line for every
# regular file of a snapshot, sorted by path.

#######################################
# Write the manifest of a snapshot.
#
# The hashes are computed by up to CAIRN_JOBS parallel sha256sum
# processes. The result goes to a temporary file that is renamed, so a
# manifest is never half written.
# Globals:
#   CAIRN_JOBS (default: nproc)
# Arguments:
#   Repository directory, snapshot name.
# Returns:
#   0 on success, 1 if any stage of the pipeline or the rename fails.
#######################################
cairn::manifest::write() {
  local repo="$1"
  local name="$2"
  local dir="${repo}/snapshots/${name}"
  local out="${repo}/manifests/${name}.sha256"
  local tmp="${out}.tmp"
  local jobs="${CAIRN_JOBS:-$(nproc)}"
  # pipefail 是全局开着的; 放进 if 条件, 失败时才能先清理再返回。
  if ! (
    cd -- "${dir}" || exit 1
    find . -type f -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 -r -P "${jobs}" -n 64 sha256sum
  ) \
    | LC_ALL=C sort -k 2 >"${tmp}"; then
    rm -f -- "${tmp}"
    return 1
  fi
  mv -T -- "${tmp}" "${out}"
}

#######################################
# Print the number of files a manifest lists.
# Arguments:
#   Repository directory, snapshot name.
# Outputs:
#   Writes the line count to stdout.
# Returns:
#   0 on success, 1 if the manifest does not exist.
#######################################
cairn::manifest::count() {
  local manifest="$1/manifests/$2.sha256"
  if [[ ! -f "${manifest}" ]]; then
    return 1
  fi
  wc -l <"${manifest}"
}

#######################################
# Check a snapshot against its manifest.
#
# sha256sum runs inside the snapshot directory and reads the manifest
# from standard input (the redirection applies to the whole subshell).
# Arguments:
#   Repository directory, snapshot name.
# Outputs:
#   Writes "ok <name> (<n> files)" to stdout, or sha256sum's
#   "<path>: FAILED" lines.
# Returns:
#   0 if every file matches, 1 on a mismatch or an unknown snapshot.
#######################################
cairn::manifest::verify() {
  local repo="$1"
  local name="$2"
  local dir="${repo}/snapshots/${name}"
  local manifest="${repo}/manifests/${name}.sha256"
  if [[ ! -d "${dir}" ]]; then
    cairn::log::err "no snapshot named ${name}"
    return 1
  fi
  if [[ ! -f "${manifest}" ]]; then
    cairn::log::err "no manifest for ${name}"
    return 1
  fi
  if ! (cd -- "${dir}" && sha256sum --check --quiet) <"${manifest}"; then
    cairn::log::err "snapshot ${name} failed verification"
    return 1
  fi
  local count
  count="$(cairn::manifest::count "${repo}" "${name}")" || return 1
  printf 'ok %s (%s files)\n' "${name}" "${count}"
}

#######################################
# Compare the manifests of two snapshots.
#
# lib/cairn/diff.awk does the comparison; the lines are then sorted by
# path in the C locale so that the order does not depend on the user's
# locale.
# Globals:
#   CAIRN_LIB
# Arguments:
#   Repository directory, old snapshot name, new snapshot name.
# Outputs:
#   Writes "A <path>", "D <path>" and "M <path>" lines to stdout.
# Returns:
#   0 on success (also when the snapshots differ), 1 on an unknown
#   snapshot, a missing manifest or a failing command.
#######################################
cairn::manifest::diff() {
  local repo="$1"
  local name
  for name in "$2" "$3"; do
    if [[ ! -d "${repo}/snapshots/${name}" ]]; then
      cairn::log::err "no snapshot named ${name}"
      return 1
    fi
    if [[ ! -f "${repo}/manifests/${name}.sha256" ]]; then
      cairn::log::err "no manifest for ${name}"
      return 1
    fi
  done
  if ! LC_ALL=C awk -f "${CAIRN_LIB}/diff.awk" \
    "${repo}/manifests/$2.sha256" "${repo}/manifests/$3.sha256" \
    | LC_ALL=C sort -k 2; then
    return 1
  fi
}
