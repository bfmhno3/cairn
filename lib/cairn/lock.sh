# shellcheck shell=bash
# Repository lock for cairn. Library: sourced by bin/cairn, not executed.
#
# Chapter 7: one cairn at a time may change a repository.

# 持有锁的文件描述符; acquire 设置, 进程退出时由内核关闭。
CAIRN_LOCK_FD=''

#######################################
# Take the exclusive lock of a repository, or fail at once.
#
# The lock belongs to the open file description behind CAIRN_LOCK_FD. It
# is never released explicitly: it ends when the last process holding
# that descriptor exits, whatever the reason (even SIGKILL). Child
# processes inherit the descriptor, so they keep the lock alive too.
# Globals:
#   CAIRN_LOCK_FD
# Arguments:
#   Repository directory.
# Outputs:
#   Creates <repo>/.lock; writes the error message to stderr.
# Returns:
#   0 if the lock is held, 1 if the lock file cannot be opened, 4 if
#   another cairn holds the lock.
#######################################
cairn::lock::acquire() {
  local repo="$1"
  exec {CAIRN_LOCK_FD}>"${repo}/.lock" || return 1
  if ! flock -n "${CAIRN_LOCK_FD}"; then
    cairn::log::err "another cairn is running on ${repo}"
    return 4
  fi
}
