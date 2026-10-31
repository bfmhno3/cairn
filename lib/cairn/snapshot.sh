# shellcheck shell=bash
# Snapshot helpers for cairn. Library: sourced by bin/cairn, not executed.
#
# Version 1 (chapter 2): a plain rsync copy, no config, no hard links.

#######################################
# Print the name of a new snapshot.
# Globals:
#   CAIRN_NOW
# Outputs:
#   Writes the UTC timestamp name (CAIRN_NOW if set) to stdout.
# Returns:
#   0 on success, 2 if CAIRN_NOW is malformed.
#######################################
cairn::snapshot::name() {
  if [[ -n "${CAIRN_NOW:-}" ]]; then
    if [[ ! "${CAIRN_NOW}" =~ ^[0-9]{8}T[0-9]{6}Z$ ]]; then
      cairn::log::err 'CAIRN_NOW must look like 20261031T090000Z'
      return 2
    fi
    printf '%s\n' "${CAIRN_NOW}"
    return 0
  fi
  printf '%(%Y%m%dT%H%M%SZ)T\n' -1
}

#######################################
# Copy SOURCE... into REPO/snapshots/<name> with rsync.
# Arguments:
#   Repository directory, one or more source paths.
# Outputs:
#   Writes the snapshot name to stdout.
# Returns:
#   0 on success, 2 on usage errors, 1 if rsync fails.
#######################################
cairn::snapshot::create() {
  if (($# < 2)); then
    cairn::log::err 'usage: cairn snapshot REPO SOURCE...'
    return 2
  fi
  local repo="$1"
  shift
  local name
  name="$(TZ=UTC cairn::snapshot::name)" || return 2
  local dest="${repo}/snapshots/${name}"
  local -a rsync_args=(--archive --relative -- "$@" "${dest}/")

  mkdir -p -- "${repo}/snapshots" || return 1
  if ! rsync "${rsync_args[@]}"; then
    cairn::log::err 'rsync failed'
    return 1
  fi
  printf '%s\n' "${name}"
}
