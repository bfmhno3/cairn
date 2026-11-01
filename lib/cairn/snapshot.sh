# shellcheck shell=bash
# Snapshot helpers for cairn. Library: sourced by bin/cairn, not executed.
#
# Chapter 5: hard-link snapshots built in <name>.partial and renamed.
# Chapter 7: repository lock, stale partials, signal handling.

# create 运行期间的状态, 供 INT/TERM/EXIT 的 trap 使用; 空表示没有。
CAIRN_SNAP_NAME=''
CAIRN_SNAP_PARTIAL=''
CAIRN_SNAP_STATS=''
CAIRN_SNAP_CHILD=''

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
# Remove an unfinished snapshot directory.
# Arguments:
#   Directory to remove (may be read-only, may not exist).
# Returns:
#   0 on success, 1 if rm fails.
#######################################
cairn::snapshot::discard() {
  # find 在目录不存在时返回 1, 那正是没有东西可删, 不算错误。
  find "$1" -type d -exec chmod u+w -- {} + 2>/dev/null || :
  rm -rf -- "$1"
}

#######################################
# Remove the unfinished snapshots a killed cairn left behind.
#
# Only called with the repository lock held, so no running cairn can
# still be writing into one of them.
# Arguments:
#   Absolute repository directory.
# Outputs:
#   Writes a warning per removed directory to stderr.
#######################################
cairn::snapshot::remove_stale() {
  local path
  for path in "$1"/snapshots/*.partial; do
    if [[ ! -d "${path}" ]]; then
      continue
    fi
    cairn::log::warn "removing stale ${path##*/}"
    cairn::snapshot::discard "${path}"
  done
}

#######################################
# EXIT trap of create: remove what a failed or interrupted run left.
# Globals:
#   CAIRN_SNAP_PARTIAL, CAIRN_SNAP_STATS
#######################################
cairn::snapshot::cleanup() {
  if [[ -n "${CAIRN_SNAP_STATS}" ]]; then
    rm -f -- "${CAIRN_SNAP_STATS}"
    CAIRN_SNAP_STATS=''
  fi
  if [[ -n "${CAIRN_SNAP_PARTIAL}" ]]; then
    cairn::snapshot::discard "${CAIRN_SNAP_PARTIAL}"
    CAIRN_SNAP_PARTIAL=''
  fi
}

#######################################
# INT/TERM trap of create: stop rsync, clean up, log, exit.
#
# The trap runs at once because create waits for rsync with the wait
# builtin. Further signals are ignored while it cleans up.
# Globals:
#   CAIRN_SNAP_NAME, CAIRN_SNAP_PARTIAL, CAIRN_SNAP_CHILD
# Arguments:
#   Exit status: 130 for SIGINT, 143 for SIGTERM.
# Outputs:
#   Appends a status=interrupted line to the log.
#######################################
cairn::snapshot::interrupt() {
  local code="$1"
  trap '' INT TERM
  if [[ -n "${CAIRN_SNAP_CHILD}" ]]; then
    kill -TERM "${CAIRN_SNAP_CHILD}" 2>/dev/null || :
    wait "${CAIRN_SNAP_CHILD}" 2>/dev/null || :
    CAIRN_SNAP_CHILD=''
  fi
  if [[ -n "${CAIRN_SNAP_PARTIAL}" ]]; then
    cairn::log::warn "interrupted, removing ${CAIRN_SNAP_NAME}.partial"
    cairn::log::file WARN snapshot "name=${CAIRN_SNAP_NAME}" \
      status=interrupted
  fi
  cairn::snapshot::cleanup
  exit "${code}"
}

#######################################
# Read the numbers cairn logs out of a saved rsync --stats report.
#
# Parses "Number of files: N (reg: R, dir: D, ...)" and "Total
# transferred file size: N bytes"; thousands separators are removed.
# Arguments:
#   File that holds rsync's standard output.
# Outputs:
#   Writes "<regular files> <bytes transferred>" to stdout.
#######################################
cairn::snapshot::stats() {
  local line
  local files=0
  local bytes=0
  while IFS= read -r line; do
    case "${line}" in
      'Number of files: '*'reg: '*)
        line="${line#*reg: }"
        files="${line%%[^0-9,]*}"
        files="${files//,/}"
        ;;
      'Total transferred file size: '*)
        line="${line#*: }"
        bytes="${line%% *}"
        bytes="${bytes//,/}"
        ;;
    esac
  done <"$1"
  printf '%s %s\n' "${files}" "${bytes}"
}

#######################################
# Create a snapshot of the configured sources with rsync.
#
# rsync writes into snapshots/<name>.partial, hard-linking unchanged
# files to the latest snapshot (--link-dest). Only after rsync, the
# manifest and the log line are done does mv rename the directory, and
# the "latest" symlink is swapped with an atomic rename. With -n
# (CAIRN_DRY_RUN=1) rsync runs with --dry-run and nothing is changed.
#
# The repository lock is taken first, then stale *.partial directories
# of a killed run are removed. rsync runs in the background and create
# waits for it, so the INT and TERM traps run at once; the EXIT trap
# removes the partial and the temporary file after any other failure.
# Globals:
#   CAIRN_REPO, CAIRN_SOURCES, CAIRN_EXCLUDES, CAIRN_DRY_RUN,
#   CAIRN_BWLIMIT (KiB/s, optional)
# Outputs:
#   Writes the snapshot name ("would create <name>" for -n) to stdout
#   and a summary line to stderr.
# Returns:
#   0 on success, 1 if the snapshot exists or a step fails, 2 if
#   CAIRN_NOW is malformed, 3 if the repository marker is missing, 4 if
#   another cairn holds the repository lock. SIGINT and SIGTERM end the
#   process with 130 and 143.
#######################################
cairn::snapshot::create() {
  cairn::repo::check "${CAIRN_REPO}" || return
  local repo
  repo="$(realpath -- "${CAIRN_REPO}")" || return 1
  cairn::lock::acquire "${repo}" || return
  if [[ "${CAIRN_DRY_RUN}" != 1 ]]; then
    cairn::snapshot::remove_stale "${repo}"
  fi
  local name
  name="$(TZ=UTC cairn::snapshot::name)" || return 2
  local final="${repo}/snapshots/${name}"
  local partial="${final}.partial"
  if [[ -e "${final}" ]]; then
    cairn::log::err "snapshot ${name} already exists"
    return 1
  fi

  local -a rsync_args=(--archive --relative --delete --numeric-ids --stats)
  local previous
  if previous="$(cairn::repo::latest "${repo}")"; then
    rsync_args+=("--link-dest=${repo}/snapshots/${previous}")
  fi
  if [[ -n "${CAIRN_BWLIMIT:-}" ]]; then
    rsync_args+=("--bwlimit=${CAIRN_BWLIMIT}")
  fi
  if [[ "${CAIRN_DRY_RUN}" == 1 ]]; then
    rsync_args+=(--dry-run)
  fi
  rsync_args+=(
    "${CAIRN_EXCLUDES[@]/#/--exclude=}"
    -- "${CAIRN_SOURCES[@]}" "${partial}/"
  )

  # 先装好 trap, 再创建临时文件和 partial 目录: 之后任何一种退出都会清理。
  CAIRN_SNAP_NAME="${name}"
  trap 'cairn::snapshot::interrupt 130' INT
  trap 'cairn::snapshot::interrupt 143' TERM
  trap cairn::snapshot::cleanup EXIT
  if [[ "${CAIRN_DRY_RUN}" != 1 ]]; then
    CAIRN_SNAP_PARTIAL="${partial}"
  fi
  # rsync 的 --stats 报告写进临时文件, 屏幕上只留它的警告和错误。
  local stats_file
  stats_file="$(mktemp)" || return 1
  CAIRN_SNAP_STATS="${stats_file}"
  local start="${SECONDS}"
  # 放到后台再 wait: 前台子进程运行时 trap 要等它结束, wait 则立即响应。
  rsync "${rsync_args[@]}" >"${stats_file}" &
  CAIRN_SNAP_CHILD=$!
  local rc=0
  wait "${CAIRN_SNAP_CHILD}" || rc=$?
  CAIRN_SNAP_CHILD=''

  if ((rc == 24)); then
    cairn::log::warn 'some files vanished during the snapshot'
  elif ((rc != 0)); then
    rm -f -- "${stats_file}"
    if [[ "${CAIRN_DRY_RUN}" != 1 ]]; then
      cairn::snapshot::discard "${partial}"
      CAIRN_SNAP_PARTIAL=''
      cairn::log::file ERROR snapshot "name=${name}" status=failed \
        "rsync_exit=${rc}"
    fi
    cairn::log::err "rsync failed with exit ${rc}"
    return 1
  fi

  local files bytes
  read -r files bytes < <(cairn::snapshot::stats "${stats_file}")
  rm -f -- "${stats_file}"

  if [[ "${CAIRN_DRY_RUN}" == 1 ]]; then
    printf 'would create %s\n' "${name}"
    return 0
  fi

  if ! mv -T -- "${partial}" "${final}"; then
    cairn::snapshot::discard "${partial}"
    CAIRN_SNAP_PARTIAL=''
    cairn::log::err "cannot rename ${name}.partial"
    return 1
  fi
  CAIRN_SNAP_PARTIAL=''
  if ! cairn::manifest::write "${repo}" "${name}"; then
    cairn::log::file ERROR snapshot "name=${name}" status=failed
    cairn::log::err "cannot write the manifest of ${name}"
    return 1
  fi
  # 先建临时符号链接再 rename: latest 始终指向一个完整的快照。
  if ! ln -sfn "snapshots/${name}" "${repo}/latest.tmp" \
    || ! mv -T -- "${repo}/latest.tmp" "${repo}/latest"; then
    cairn::log::err 'cannot update the latest link'
    return 1
  fi

  local seconds=$((SECONDS - start))
  cairn::log::file INFO snapshot "name=${name}" status=ok \
    "files=${files}" "bytes=${bytes}" "seconds=${seconds}"
  cairn::log::info "snapshot ${name}: ${files} files," \
    "${bytes} bytes transferred in ${seconds} s"
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
