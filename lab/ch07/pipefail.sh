# shellcheck shell=bash
# Shows: a pipeline's status is the last command's; `set -o pipefail`
# makes it the last non-zero status. PIPESTATUS keeps every stage.
# `yes | head -n 1` becomes 141 (128 + SIGPIPE) under pipefail.
echo '--- default ---'
false | true
echo "false | true            -> $?"
false | cat >/dev/null
echo "false | cat             -> $? (PIPESTATUS: ${PIPESTATUS[*]})"

echo '--- set -o pipefail ---'
set -o pipefail
false | true
echo "false | true            -> $?"
(exit 3) | (exit 5) | true
echo "(exit 3)|(exit 5)|true  -> $? (PIPESTATUS: ${PIPESTATUS[*]})"
yes | head -n 1 >/dev/null
echo "yes | head -n 1         -> $? (141 = 128 + 13, SIGPIPE)"
set +o pipefail
yes | head -n 1 >/dev/null
echo "same without pipefail   -> $?"

echo '--- pipefail plus set -e (in a subshell) ---'
(
  set -o pipefail -o errexit
  echo before
  false | true
  echo 'not printed: the pipeline failed'
)
echo "subshell status: $?"
