# shellcheck shell=bash
# Shows: shellcheck -s sh on the bashism fixture. -s sh makes shellcheck
# check against POSIX sh instead of the dialect the shebang names, so
# every construct that dash cannot run is reported. Exit status 1 means
# findings; the lab prints it and exits 0.
cd "${CAIRN_ROOT}" || exit 1
shellcheck -s sh -f gcc lab/ch10/fixtures/bashisms.txt
echo "shellcheck exit status: $?"
