# shellcheck shell=bash
# Exercise solution: classify each argument as alias, keyword, function,
# builtin or file with `type -t`.
# Usage: ex_which_kind.sh NAME...
if (($# == 0)); then
  set -- ls cd if type ex_demo_function
fi
ex_demo_function() { :; }
for name in "$@"; do
  kind="$(type -t "${name}")" || kind=missing
  printf '%-18s %s\n' "${name}" "${kind}"
done
