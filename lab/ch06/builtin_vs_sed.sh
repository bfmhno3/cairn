# shellcheck shell=bash
# Shows: "prefer builtins" has two halves. In a loop over 5000 lines,
# ${line//a/b} (builtin) beats calling sed once per line by a large
# factor, but one sed over the whole file beats the builtin loop.
# Median of 5 runs, in ms.
seq 1 5000 | awk '{ print "banana " $1 " a-a-a" }' >lines.txt
wc -l <lines.txt

median_us() {
  local -a times=()
  local start
  for _ in 1 2 3 4 5; do
    start="${EPOCHREALTIME/./}"
    "$@" >/dev/null
    times+=($((${EPOCHREALTIME/./} - start)))
  done
  local mid
  mid="$(printf '%s\n' "${times[@]}" | sort -n | sed -n 3p)"
  echo "${mid}"
}
builtin_loop() {
  local line
  while IFS= read -r line; do
    printf '%s\n' "${line//a/A}"
  done <lines.txt
}
sed_per_line() {
  local line
  while IFS= read -r line; do
    printf '%s\n' "${line}" | sed 's/a/A/g'
  done <lines.txt
}
sed_once() {
  sed 's/a/A/g' lines.txt
}

# 三种写法的输出必须一致, 否则比较没有意义。
a="$(builtin_loop | cksum)"
b="$(sed_once | cksum)"
if [[ "${a}" != "${b}" ]]; then
  echo 'outputs differ' >&2
  exit 1
fi

t_builtin="$(median_us builtin_loop)"
t_per_line="$(median_us sed_per_line)"
t_once="$(median_us sed_once)"
ms() { printf '%d.%d' "$(($1 / 1000))" "$(($1 % 1000 / 100))"; }
echo "builtin loop, \${line//a/A}:  $(ms "${t_builtin}") ms"
echo "loop calling sed per line: $(ms "${t_per_line}") ms"
echo "one sed over the file:     $(ms "${t_once}") ms"
printf 'sed per line / builtin loop: %d.%dx\n' \
  "$((t_per_line / t_builtin))" "$((t_per_line * 10 / t_builtin % 10))"
printf 'builtin loop / one sed:      %d.%dx\n' \
  "$((t_builtin / t_once))" "$((t_builtin * 10 / t_once % 10))"
