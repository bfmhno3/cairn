# shellcheck shell=bash
# Shows: what `bash --posix` changes and what it does not. Posix mode
# changes behavior (special builtins, error handling), it does not remove
# bash-only syntax. Every line is one `bash --posix -c` next to the same
# command in plain bash.
# 片段要原样交给子 shell 展开, 所以用单引号。
# shellcheck disable=SC2016

#######################################
# Run one snippet under bash and under bash --posix.
# Arguments:
#   The snippet.
#######################################
both() {
  local snippet="$1"
  printf '$ %s\n' "${snippet}"
  printf '  bash:         '
  bash -c "${snippet}" 2>&1 | tr '\n' ' '
  printf '[exit %d]\n' "${PIPESTATUS[0]}"
  printf '  bash --posix: '
  bash --posix -c "${snippet}" 2>&1 | tr '\n' ' '
  printf '[exit %d]\n' "${PIPESTATUS[0]}"
}

echo '--- same in both: [ is a builtin either way ---'
both 'type -t ['
echo '--- differs: a function may not take a special builtin name ---'
both 'export() { echo fn; }; export; echo after'
echo '--- differs: an error in a special builtin ends the shell ---'
both 'set -o nosuchopt; echo after'
echo '--- differs: SHELLOPTS lists posix ---'
both 'echo "${SHELLOPTS}"'
echo '--- not different: bash-only syntax is still accepted ---'
both 'echo {a,b}; [[ x == x ]] && echo dbl; a=(1 2); echo "${a[1]}"'
