# shellcheck shell=bash disable=SC2016
# Shows: ${p##*/} (builtin, no process) vs $(basename "$p") (fork + exec).
# 10000 calls each, median of 5 runs, in ms.
median_us() {
  local -a times=()
  local start
  for _ in 1 2 3 4 5; do
    start="${EPOCHREALTIME/./}"
    "$@"
    times+=($((${EPOCHREALTIME/./} - start)))
  done
  printf '%s\n' "${times[@]}" | sort -n | sed -n 3p
}

# shellcheck disable=SC2034 # the result is deliberately thrown away
run_expansion() {
  local i
  local base
  for ((i = 0; i < 10000; i++)); do
    base="${p##*/}"
  done
}

# shellcheck disable=SC2034 # the result is deliberately thrown away
run_basename() {
  local i
  local base
  for ((i = 0; i < 10000; i++)); do
    base="$(basename "${p}")"
  done
}

p=/home/me/docs/report.final.tar.gz
a="$(median_us run_expansion)"
b="$(median_us run_basename)"
printf '${p##*/}:         %d.%d ms\n' "$((a / 1000))" "$((a % 1000 / 100))"
printf '$(basename "$p"): %d.%d ms\n' "$((b / 1000))" "$((b % 1000 / 100))"
printf 'ratio: %dx\n' "$((b / a))"
