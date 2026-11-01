# shellcheck shell=bash
# Repository helpers for cairn. Library: sourced by bin/cairn.
#
# A repository is a directory with a cairn.repo marker file, plus
# snapshots/, manifests/ and logs/.

#######################################
# Create a new repository.
# Arguments:
#   Repository directory (resolved with realpath -m).
# Outputs:
#   Writes the absolute directory to stdout when it was created; an
#   existing repository is reported on stderr.
# Returns:
#   0 on success (also if the repository already exists), 1 if a
#   command fails, 3 if the directory exists and is not empty.
#######################################
cairn::repo::init() {
  local dir
  dir="$(realpath -m -- "$1")" || return 1
  if [[ -e "${dir}/cairn.repo" ]]; then
    cairn::log::info "${dir} is already a cairn repository"
    return 0
  fi
  if [[ -e "${dir}" ]]; then
    local entry=''
    if [[ -d "${dir}" ]]; then
      entry="$(find "${dir}" -mindepth 1 -print -quit)" || return 1
    else
      entry="${dir}"
    fi
    if [[ -n "${entry}" ]]; then
      cairn::log::err "${dir} exists and is not empty"
      return 3
    fi
  fi
  mkdir -p -- "${dir}/snapshots" "${dir}/manifests" "${dir}/logs" \
    || return 1
  printf 'cairn-repo 1\n' >"${dir}/cairn.repo" || return 1
  printf '%s\n' "${dir}"
}

#######################################
# Check that a directory is a cairn repository.
# Arguments:
#   Repository directory.
# Returns:
#   0 if the marker file exists, 3 otherwise.
#######################################
cairn::repo::check() {
  local dir="$1"
  if [[ ! -f "${dir}/cairn.repo" ]]; then
    cairn::log::err \
      "${dir} is not a cairn repository (run 'cairn init ${dir}')"
    return 3
  fi
}

#######################################
# Print the snapshot names of a repository, oldest to newest.
# Names are fixed-width UTC timestamps, so C-locale order is time order;
# *.partial directories (unfinished snapshots) are skipped.
# Arguments:
#   Repository directory.
# Outputs:
#   Writes one name per line to stdout.
#######################################
cairn::repo::snapshots() {
  local LC_COLLATE=C
  local path name
  for path in "$1"/snapshots/*; do
    if [[ ! -d "${path}" ]]; then
      continue
    fi
    name="${path##*/}"
    if [[ "${name}" == *.partial ]]; then
      continue
    fi
    printf '%s\n' "${name}"
  done
}

#######################################
# Print the name of the newest snapshot.
# Arguments:
#   Repository directory.
# Outputs:
#   Writes the name to stdout.
# Returns:
#   0 on success, 1 if the repository has no snapshot.
#######################################
cairn::repo::latest() {
  local -a names
  readarray -t names < <(cairn::repo::snapshots "$1")
  if ((${#names[@]} == 0)); then
    return 1
  fi
  printf '%s\n' "${names[-1]}"
}

#######################################
# Print the disk space each snapshot added, oldest to newest.
#
# One du call sees all snapshot directories, so a hard-linked file is
# counted only for the first snapshot that holds it; each row is the
# space that snapshot added. numfmt turns the byte counts into 1024-based
# units (1.5K, 20M).
# Arguments:
#   Repository directory.
# Outputs:
#   Writes one size per snapshot to stdout, in snapshot order.
# Returns:
#   0 on success, 1 if du or numfmt fails.
#######################################
cairn::repo::sizes() {
  local -a dirs
  local name
  while IFS= read -r name; do
    dirs+=("$1/snapshots/${name}")
  done < <(cairn::repo::snapshots "$1")
  if ((${#dirs[@]} == 0)); then
    return 0
  fi
  local usage
  usage="$(du -s --block-size=1 -- "${dirs[@]}")" || return 1
  if ! cut -f 1 <<<"${usage}" | numfmt --to=iec; then
    return 1
  fi
}
