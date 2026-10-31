# shellcheck shell=bash
# Shows: $@, "$@", $* and "$*" with three arguments, one containing
# spaces and one empty.
args="${CAIRN_ROOT}/lab/ch02/args.sh"
set -- one 'two words' ''

echo '--- $@ (unquoted)'
# shellcheck disable=SC2068 # BAD: deliberate
bash "${args}" $@
echo '--- "$@"'
bash "${args}" "$@"
echo '--- $* (unquoted)'
# shellcheck disable=SC2048,SC2086 # BAD: deliberate
bash "${args}" $*
echo '--- "$*"'
bash "${args}" "$*"
echo '--- "$*" with IFS=,'
IFS=,
bash "${args}" "$*"
unset IFS
