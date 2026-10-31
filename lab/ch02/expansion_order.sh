# shellcheck shell=bash
# Shows: the order of expansions, one probe per stage. Each probe is a
# command line given to args.sh; `set -x` shows the words after expansion.
# The trace goes to a copy of stdout (fd 3, via BASH_XTRACEFD) so it
# interleaves with the output of args.sh in order and is not captured by
# $(...).
# BAD: every probe below is deliberately unquoted.
# shellcheck disable=SC2016,SC2046,SC2116,SC2086,SC2035,SC2028,SC1001,SC2051
exec 3>&1
BASH_XTRACEFD=3
args="${CAIRN_ROOT}/lab/ch02/args.sh"
cd "${LAB_TMP}" || exit 1
touch a.txt b.txt
HOME=/home/demo
n=3
v='x y'

echo '--- 1 brace expansion: {a,b}{1,2}'
set -x
bash "${args}" {a,b}{1,2}
set +x
echo '--- 2 tilde expansion: ~/docs'
set -x
bash "${args}" ~/docs
set +x
echo '--- 3 parameter expansion: "${v}" ${v:-none}'
set -x
bash "${args}" "${v}" "${v:-none}"
set +x
echo '--- 4 arithmetic expansion: $((n * 2))'
set -x
bash "${args}" "$((n * 2))"
set +x
echo '--- 5 command substitution: $(echo one two)'
set -x
bash "${args}" $(echo one two)
set +x
echo '--- 6 word splitting: ${v} unquoted'
set -x
bash "${args}" ${v}
set +x
echo '--- 7 pathname expansion: *.txt'
set -x
bash "${args}" *.txt
set +x
echo '--- 8 quote removal: "q" '"'s'"' \e'
set -x
bash "${args}" "q" 's' \e
set +x
echo '--- order: brace runs before parameter, so {1..$n} stays literal'
set -x
bash "${args}" {1..$n}
set +x
