# shellcheck shell=bash
# Shows: checkbashisms on the same fixture as bashisms_fail.sh. It reads
# the file, runs nothing, and reports each bashism with its line. Its exit
# status is 1 when it finds something; the lab prints that status and
# exits 0.
cd "${CAIRN_ROOT}" || exit 1
checkbashisms lab/ch10/fixtures/bashisms.txt
echo "checkbashisms exit status: $?"
