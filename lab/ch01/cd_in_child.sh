# shellcheck shell=bash
# Shows: `cd` in a child process does not move the parent; `source` runs
# in the current shell, so it does.
cd "${LAB_TMP}" || exit 1
echo "start:           ${PWD}"
bash -c 'cd /; echo "inside child:    ${PWD}"'
echo "after child:     ${PWD}"
echo 'cd /' >go_root.sh
# shellcheck source=/dev/null
source ./go_root.sh
echo "after source:    ${PWD}"
