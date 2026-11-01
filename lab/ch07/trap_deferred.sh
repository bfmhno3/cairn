# shellcheck shell=bash
# Shows: bash runs a trap only between commands. While a foreground
# child (`sleep 5`) runs, a SIGINT sent to the script waits until the
# child ends. With `sleep 5 & wait`, the wait builtin returns at once and
# the trap runs immediately. The lab prints both latencies in ms.
# `set -m` gives background jobs the default INT disposition; without it
# a non-interactive shell starts them with SIGINT ignored, and a trap on
# an ignored signal never fires.
set -m

now_us() {
  printf '%s\n' "${EPOCHREALTIME/./}"
}

cat >child_fg.sh <<'CHILD'
trap 'printf "%s\n" "${EPOCHREALTIME/./}" >trap_time; exit 130' INT
: >ready
sleep 5
CHILD

cat >child_wait.sh <<'CHILD'
trap 'printf "%s\n" "${EPOCHREALTIME/./}" >trap_time; kill "${sleeper}"
  exit 130' INT
sleep 5 &
sleeper=$!
: >ready
wait "${sleeper}"
CHILD

# measure SCRIPT: start it, wait for its ready marker, sleep 1 s, send
# SIGINT, wait for it and print how long the trap needed.
measure() {
  rm -f ready trap_time
  bash "$1" &
  local pid=$!
  while [[ ! -e ready ]]; do
    sleep 0.05
  done
  sleep 1
  local sent
  sent="$(now_us)"
  kill -INT "${pid}"
  wait "${pid}"
  local status=$?
  local ran
  ran="$(<trap_time)"
  echo "$2: exit status ${status}, trap ran $(((ran - sent) / 1000)) ms" \
    'after kill -INT'
}

measure child_fg.sh 'foreground sleep 5'
measure child_wait.sh 'sleep 5 & wait   '
