# shellcheck shell=bash
# Shows: the ERR trap of bin/cairn. The log file is made read-only, so
# `cairn::log::file` fails after the snapshot itself is complete. Without
# -v cairn prints one line, with -v one `at <func> (<file>:<line>)` line
# per frame. The failing command ends cairn through errexit with its
# own status (1), so this lab ends in _fail.sh.
src="${LAB_TMP}/src"
repo="${LAB_TMP}/repo"
conf="${LAB_TMP}/cairn.conf"
mkdir "${src}" || exit 2
echo hello >"${src}/a.txt"
cairn -c "${conf}" init "${repo}" 2>/dev/null || exit 2
printf 'source = %s\n' "${src}" >>"${conf}"
: >"${repo}/logs/cairn.log"
chmod a-w "${repo}/logs/cairn.log"

# 路径每次不同; 换成占位符, 输出才可比较。
show() {
  sed -e "s|${CAIRN_ROOT}|<cairn>|g" -e "s|${LAB_TMP}|<tmp>|g"
}

echo '--- without -v ---'
CAIRN_NOW=20261031T090000Z cairn -q -c "${conf}" snapshot 2>&1 | show
echo "exit status: ${PIPESTATUS[0]}"

echo '--- with -v ---'
CAIRN_NOW=20261031T100000Z cairn -q -v -c "${conf}" snapshot 2>&1 | show
status=${PIPESTATUS[0]}
echo "exit status: ${status}"
exit "${status}"
