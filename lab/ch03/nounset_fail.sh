# shellcheck shell=bash
# Shows: with `set -u` a typo in a variable name aborts the script
# instead of silently expanding to nothing. Must exit non-zero.
set -o nounset

target_dir=/tmp/some/dir
echo "without set -u, \$tpyo would be empty; with it: abort"
echo "safe use with a default: [${tpyo:-}]"
# BAD: the name is misspelled on purpose.
# shellcheck disable=SC2154
echo "rm -rf ${tpyo}/cache"
echo "never printed ${target_dir}"
