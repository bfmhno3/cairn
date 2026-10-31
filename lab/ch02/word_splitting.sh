# shellcheck shell=bash
# Shows: word splitting on spaces, an empty unquoted variable vanishing,
# and a custom IFS.
args="${CAIRN_ROOT}/lab/ch02/args.sh"
file='my notes.txt'
empty=''

echo '--- unquoted: two words'
# shellcheck disable=SC2086 # BAD: deliberate
bash "${args}" ${file}
echo '--- quoted: one word'
bash "${args}" "${file}"
echo '--- empty variable, unquoted: the argument vanishes'
# shellcheck disable=SC2086 # BAD: deliberate
bash "${args}" ${empty}
echo '--- empty variable, quoted: one empty argument'
bash "${args}" "${empty}"
echo '--- IFS=: splits only on colons'
path='/usr/bin:/opt/my tools:/bin'
IFS=:
# shellcheck disable=SC2086 # BAD: deliberate
bash "${args}" ${path}
unset IFS
echo '--- IFS unset again: back to blank, tab, newline'
# shellcheck disable=SC2086 # BAD: deliberate
bash "${args}" ${path}
echo '--- read -a with a local IFS'
IFS=: read -r -a parts <<<"${path}"
bash "${args}" "${parts[@]}"
