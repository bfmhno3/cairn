# shellcheck shell=bash
# Shows: $(date +%s) forks a process; printf '%(%s)T' does not.
# 1000 calls each, median of 5 runs, in ms.
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
run_date() {
  local i now
  for ((i = 0; i < 1000; i++)); do
    now="$(date +%s)"
  done
  : "${now}"
}
run_printf() {
  local i now
  for ((i = 0; i < 1000; i++)); do
    printf -v now '%(%s)T' -1
  done
  : "${now}"
}
d="$(median_us run_date)"
p="$(median_us run_printf)"
printf '1000 x %s: %d.%d ms\n' "\$(date +%s)" \
  "$((d / 1000))" "$((d % 1000 / 100))"
printf '1000 x %s: %d.%d ms\n' "printf '%(%s)T'" \
  "$((p / 1000))" "$((p % 1000 / 100))"
printf 'ratio: %d.%dx\n' "$((d / p))" "$((d * 10 / p % 10))"
