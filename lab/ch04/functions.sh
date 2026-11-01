# shellcheck shell=bash
# Shows: status vs stdout, local, FUNCNAME, recursion and its cost.
# Factorial: 15 calls per run, subshell form vs variable form, median
# of 5 runs.
is_even() {
  (($1 % 2 == 0))
}
double() {
  echo "$(($1 * 2))"
}
if is_even 4; then
  echo 'is_even 4: status 0 (success)'
fi
is_even 3
echo "is_even 3: status $?"
echo "double 21 prints: $(double 21)"

x='global'
shadow() {
  local x='local'
  echo "inside: ${x}"
}
shadow
echo "outside: ${x}"

outer() {
  inner
}
inner() {
  echo "FUNCNAME: ${FUNCNAME[*]}"
}
outer

fact_sub() {
  if (($1 <= 1)); then
    echo 1
  else
    local prev
    prev="$(fact_sub $(($1 - 1)))"
    echo "$(($1 * prev))"
  fi
}
fact_var() {
  if (($1 <= 1)); then
    result=1
  else
    fact_var $(($1 - 1))
    result=$(($1 * result))
  fi
}
echo "fact_sub 15 = $(fact_sub 15)"
fact_var 15
echo "fact_var 15 = ${result}"

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
run_sub() {
  local i
  for ((i = 0; i < 20; i++)); do
    fact_sub 15 >/dev/null
  done
}
run_var() {
  local i
  for ((i = 0; i < 20; i++)); do
    fact_var 15
  done
}
s="$(median_us run_sub)"
v="$(median_us run_var)"
printf 'fact_sub (subshell): %d.%d ms for 20 x fact 15\n' \
  "$((s / 1000))" "$((s % 1000 / 100))"
printf 'fact_var (variable): %d.%d ms for 20 x fact 15\n' \
  "$((v / 1000))" "$((v % 1000 / 100))"
printf 'ratio: %d.%dx\n' "$((s / v))" "$((s * 10 / v % 10))"
