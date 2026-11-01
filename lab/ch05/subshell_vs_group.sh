# shellcheck shell=bash
# Shows: ( ) runs in a forked subshell, { } runs in the current shell.
# $$ is always the main shell's PID, $BASHPID is the PID of the shell
# that is running right now.
echo "main:  \$\$=$$ BASHPID=${BASHPID}"

echo '--- ( ): a subshell ---'
# shellcheck disable=SC2030
(
  echo "inside: \$\$=$$ BASHPID=${BASHPID}"
  var=changed
  cd /
)
# shellcheck disable=SC2031
echo "after: var='${var:-unset}' pwd is still ${PWD##*/}"

echo '--- { }: a group in the same shell ---'
{
  echo "inside: \$\$=$$ BASHPID=${BASHPID}"
  var=changed
}
echo "after: var='${var}'"

echo '--- a group can share one redirection ---'
{
  echo one
  echo two
} >"${LAB_TMP}/group.txt"
wc -l <"${LAB_TMP}/group.txt"

echo '--- cmd substitution and pipelines also fork ---'
echo "in \$(...): $(printf '%s' "${BASHPID}")"
echo x | { echo "right side of a pipe: ${BASHPID}"; }

echo '--- exit in a subshell leaves the parent alone ---'
(exit 7)
echo "status of (exit 7): $?"
