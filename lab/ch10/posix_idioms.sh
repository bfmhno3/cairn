# shellcheck shell=bash
# Shows: the POSIX replacements for the usual bash habits, in one script
# that runs under dash: case for patterns, set -- as the only array,
# printf, command -v, ${var#pat}, $(( )) and getopts. The lab writes the
# script to $LAB_TMP, checks it with `dash -n` and checkbashisms, then
# runs it under dash.
script="${LAB_TMP}/idioms.sh"
cat >"${script}" <<'IDIOMS'
#!/bin/sh
name=snapshot-2026.tar.gz
case "${name}" in
  *.tar.gz | *.tgz) echo "case: ${name} is a tarball" ;;
  *) echo "case: ${name} is something else" ;;
esac

set -- one 'two words' three
echo "set --: $# items, second is '$2'"
set -- "$@" four
for item in "$@"; do
  printf '  [%s]\n' "${item}"
done

printf 'printf: %s|%5d|%-6s|\n' x 42 ab

command -v dash >/dev/null && echo 'command -v: dash found'
command -v no_such_command_xyz >/dev/null 2>&1 \
  || echo 'command -v: no_such_command_xyz missing'

path=/a/b/c.txt
echo "expansion: ${path##*/} ${path%/*} ${path%.txt} ${#path}"
echo "arithmetic: $((2 + 3 * 4)) $((17 % 5)) $((1 << 4))"

parse() (
  OPTIND=1
  verbose=0
  out=none
  while getopts 'vo:' opt; do
    case "${opt}" in
      v) verbose=1 ;;
      o) out="${OPTARG}" ;;
      *) return 2 ;;
    esac
  done
  shift "$((OPTIND - 1))"
  echo "getopts: verbose=${verbose} out=${out} rest=$*"
)
parse -v -o file.txt a b
IDIOMS
dash -n "${script}" && echo 'dash -n: ok'
checkbashisms "${script}" && echo 'checkbashisms: clean'
echo '--- dash idioms.sh ---'
dash "${script}"
