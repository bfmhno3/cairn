# shellcheck shell=bash
# Shows: echo is not portable. Each shell runs `echo 'a\nb'` and
# `echo -n x; echo`; the output is printed with printf %q so that a real
# newline and a backslash followed by n look different. An echo that
# does not understand -n prints it as text.
printf '%-14s %-14s %s\n' shell "echo 'a\\nb'" 'echo -n x'
row() {
  local label="$1"
  shift
  local a n
  a="$("$@" -c "echo 'a\\nb'")"
  n="$("$@" -c 'echo -n x; echo')"
  printf '%-14s %-14q %q\n' "${label}" "${a}" "${n}"
}
row dash dash
row bash bash
row 'busybox sh' "${CAIRN_BUSYBOX}" sh
row yash yash
row mksh mksh
