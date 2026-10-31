# shellcheck shell=bash
# shellcheck disable=SC2016 # the lines are expanded by the child bash
# Exercise solution: how many arguments does `cmd LINE` receive after
# expansion? Each LINE is pasted after `set --` in a child bash, which
# expands it exactly as it would for a real command, and args.sh prints
# the result. Only run lines you typed yourself.
# Usage: ex_count_args.sh 'LINE'...
if (($# == 0)); then
  set -- 'a b "c d"' '{a,b}{1,2}' '"$HOME"/*.nothing' '$(echo x  y) ""'
fi
export ARGS_SH="${CAIRN_ROOT}/lab/ch02/args.sh"
for line in "$@"; do
  printf '=== cmd %s\n' "${line}"
  bash -c "set -- ${line}; bash \"\${ARGS_SH}\" \"\$@\""
done
