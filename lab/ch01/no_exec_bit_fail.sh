# shellcheck shell=bash
# Shows: running a file without the exec bit as ./file fails with 126.
cd "${LAB_TMP}" || exit 1
printf 'echo hi\n' >plain
./plain
status=$?
echo "exit status: ${status}"
exit "${status}"
