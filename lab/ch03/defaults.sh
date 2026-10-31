# shellcheck shell=bash disable=SC2016
# Shows: the default-value operators, each with an unset, an empty and
# a set variable. `-` tests for unset; `:-` tests for unset or empty.
strip_where() {
  printf '%s\n' "${1#*line [0-9]*: }"
}

unset unset_v
empty_v=''
set_v=value

printf '%-18s %-10s %-10s %-10s\n' EXPRESSION unset empty set
printf '%-18s %-10s %-10s %-10s\n' '${v-dflt}' \
  "[${unset_v-dflt}]" "[${empty_v-dflt}]" "[${set_v-dflt}]"
printf '%-18s %-10s %-10s %-10s\n' '${v:-dflt}' \
  "[${unset_v:-dflt}]" "[${empty_v:-dflt}]" "[${set_v:-dflt}]"
printf '%-18s %-10s %-10s %-10s\n' '${v+alt}' \
  "[${unset_v+alt}]" "[${empty_v+alt}]" "[${set_v+alt}]"
printf '%-18s %-10s %-10s %-10s\n' '${v:+alt}' \
  "[${unset_v:+alt}]" "[${empty_v:+alt}]" "[${set_v:+alt}]"

echo '--- := assigns the default as well'
unset a b
b=''
echo "a=[${a:=fallback}] b=[${b:=fallback}]"
echo "afterwards a=[${a}] b=[${b}]"

echo '--- :? aborts with a message (run in subshells)'
msg="$(
  (: "${unset_v:?needs a value}") 2>&1
)"
strip_where "${msg}"
msg="$(
  (: "${empty_v:?needs a value}") 2>&1
)"
strip_where "${msg}"
msg="$(
  (
    : "${empty_v?never aborts, empty_v is set}"
    echo 'no abort with ?: empty_v is set'
  ) 2>&1
)"
strip_where "${msg}"
