# shellcheck shell=bash
# Shows: a builtin call vs forking and exec'ing the external binary.
# 2000 calls each, median of 5 runs, in ms.
external="$(type -P true)"
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
run_builtin() {
  local i
  for ((i = 0; i < 2000; i++)); do
    true
  done
}
run_external() {
  local i
  for ((i = 0; i < 2000; i++)); do
    "${external}"
  done
}
b="$(median_us run_builtin)"
e="$(median_us run_external)"
printf 'builtin true:  %d.%d ms\n' "$((b / 1000))" "$((b % 1000 / 100))"
printf 'external true: %d.%d ms (%s)\n' \
  "$((e / 1000))" "$((e % 1000 / 100))" "${external}"
printf 'ratio: %d.%dx\n' "$((e / b))" "$((e * 10 / b % 10))"
