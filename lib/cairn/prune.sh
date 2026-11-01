# shellcheck shell=bash
# Retention policy for cairn. Library: sourced by bin/cairn.
#
# select is pure (names in, decisions out); run applies the decisions.

#######################################
# Decide which snapshots to keep.
#
# Walks the names newest to oldest. A name is kept as "last" while fewer
# than KEEP_LAST were kept; else as "daily" if its day is not yet seen
# among last/daily and fewer than KEEP_DAILY days were kept that way;
# else as "weekly" if its ISO week is not yet seen among last/weekly and
# fewer than KEEP_WEEKLY weeks were kept that way; else it is removed.
# Arguments:
#   KEEP_LAST, KEEP_DAILY, KEEP_WEEKLY, then snapshot names oldest to
#   newest (YYYYMMDDTHHMMSSZ).
# Outputs:
#   Writes "keep <name> <reason>" or "remove <name>" lines to stdout,
#   newest first.
#######################################
cairn::prune::select() {
  local keep_last="$1"
  local keep_daily="$2"
  local keep_weekly="$3"
  shift 3
  local -A seen_day=()
  local -A seen_week=()
  local -i n_last=0 n_daily=0 n_weekly=0
  local i name day week
  for ((i = $#; i >= 1; i--)); do
    name="${!i}"
    day="${name:0:8}"
    if ((n_last < keep_last)); then
      week="$(cairn::prune::week "${name}")" || return 1
      seen_day["${day}"]=1
      seen_week["${week}"]=1
      ((n_last += 1))
      printf 'keep %s last\n' "${name}"
      continue
    fi
    if [[ -z "${seen_day[${day}]:-}" ]] && ((n_daily < keep_daily)); then
      seen_day["${day}"]=1
      ((n_daily += 1))
      printf 'keep %s daily\n' "${name}"
      continue
    fi
    if ((n_weekly < keep_weekly)); then
      week="$(cairn::prune::week "${name}")" || return 1
      if [[ -z "${seen_week[${week}]:-}" ]]; then
        seen_week["${week}"]=1
        ((n_weekly += 1))
        printf 'keep %s weekly\n' "${name}"
        continue
      fi
    fi
    printf 'remove %s\n' "${name}"
  done
}

#######################################
# Print the ISO week (YYYY-Www) of a snapshot name.
# Arguments:
#   Snapshot name.
# Outputs:
#   Writes the week to stdout.
# Returns:
#   0 on success, 1 if date rejects the name.
#######################################
cairn::prune::week() {
  local name="$1"
  date -u -d "${name:0:8} ${name:9:2}:${name:11:2}:${name:13:2}" \
    +%G-W%V
}

#######################################
# Apply the retention policy to the repository.
# Globals:
#   CAIRN_REPO, CAIRN_KEEP_LAST, CAIRN_KEEP_DAILY, CAIRN_KEEP_WEEKLY,
#   CAIRN_DRY_RUN, CAIRN_VERBOSE
# Outputs:
#   Writes "removed <name>" (or "would remove <name>" when dry-running)
#   per removed snapshot; with CAIRN_VERBOSE=1 also "keep <name>
#   (<reason>)".
# Returns:
#   0 on success, 1 if a deletion fails, 3 if CAIRN_REPO is not a
#   repository.
#######################################
cairn::prune::run() {
  cairn::repo::check "${CAIRN_REPO}" || return
  local -a names decisions
  readarray -t names < <(cairn::repo::snapshots "${CAIRN_REPO}")
  readarray -t decisions < <(
    cairn::prune::select "${CAIRN_KEEP_LAST}" "${CAIRN_KEEP_DAILY}" \
      "${CAIRN_KEEP_WEEKLY}" "${names[@]}"
  )
  local line action name reason
  local status=0
  for line in "${decisions[@]}"; do
    read -r action name reason <<<"${line}"
    case "${action}" in
      keep)
        if [[ "${CAIRN_VERBOSE}" == 1 ]]; then
          printf 'keep %s (%s)\n' "${name}" "${reason}"
        fi
        ;;
      remove)
        if [[ "${CAIRN_DRY_RUN}" == 1 ]]; then
          printf 'would remove %s\n' "${name}"
        elif cairn::prune::remove "${name}"; then
          printf 'removed %s\n' "${name}"
        else
          cairn::log::err "cannot remove ${name}"
          status=1
        fi
        ;;
    esac
  done
  return "${status}"
}

#######################################
# Delete one snapshot and its manifest.
# Globals:
#   CAIRN_REPO
# Arguments:
#   Snapshot name.
# Returns:
#   0 on success, 1 on failure.
#######################################
cairn::prune::remove() {
  local name="$1"
  chmod -R u+w -- "${CAIRN_REPO}/snapshots/${name}" || return 1
  rm -rf -- "${CAIRN_REPO}/snapshots/${name}" || return 1
  rm -f -- "${CAIRN_REPO}/manifests/${name}.sha256"
}
