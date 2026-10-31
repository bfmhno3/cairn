# shellcheck shell=bash
# Snapshot helpers for cairn. Library: sourced by bin/cairn, not executed.
#
# Chapter 3: a plain rsync copy driven by the config, no hard links yet.

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
# Copy the configured sources into REPO/snapshots/<name> with rsync.
# Globals:
#   CAIRN_REPO, CAIRN_SOURCES, CAIRN_EXCLUDES
# Outputs:
#   Writes the snapshot name to stdout.
# Returns:
#   0 on success, 1 if the snapshot exists or rsync fails, 2 if
#   CAIRN_NOW is malformed, 3 if the repository marker is missing.
#######################################
cairn::snapshot::create() {
  cairn::repo::check "${CAIRN_REPO}" || return
  local name
  name="$(TZ=UTC cairn::snapshot::name)" || return 2
  local dest="${CAIRN_REPO}/snapshots/${name}"
  if [[ -e "${dest}" ]]; then
    cairn::log::err "snapshot ${name} already exists"
    return 1
  fi
  local -a rsync_args=(
    --archive --relative
    "${CAIRN_EXCLUDES[@]/#/--exclude=}"
    -- "${CAIRN_SOURCES[@]}" "${dest}/"
  )
  if ! rsync "${rsync_args[@]}"; then
    cairn::log::err 'rsync failed'
    return 1
  fi
  printf '%s\n' "${name}"
}

#######################################
# Chapter 2 form: copy SOURCE... into REPO/snapshots/<name>.
#
# Kept so that the chapter 2 labs still run unchanged: bin/cairn routes
# "cairn snapshot REPO SOURCE..." (two or more arguments) here. It uses
# no config file and does not check the repository marker.
# Arguments:
#   Repository directory, one or more source paths.
# Outputs:
#   Writes the snapshot name to stdout.
# Returns:
#   0 on success, 2 if CAIRN_NOW is malformed, 1 if rsync fails.
#######################################
cairn::snapshot::create_adhoc() {
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
