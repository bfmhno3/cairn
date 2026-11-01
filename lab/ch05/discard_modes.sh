# shellcheck shell=bash
# Shows: a failed snapshot is discarded without touching the older one.
# Snapshot 1 holds a 0444 file. Snapshot 2 adds a nonexistent source, so
# rsync exits 23 and cairn discards the .partial, whose files are hard
# links to snapshot 1. The 0444 mode in snapshot 1 must not change.
src="${LAB_TMP}/src"
repo="${LAB_TMP}/repo"
conf="${LAB_TMP}/cairn.conf"
export TZ=UTC
mkdir "${src}"
echo locked >"${src}/locked.txt"
chmod 0444 "${src}/locked.txt"
cairn -c "${conf}" init "${repo}" 2>/dev/null || exit 1
printf 'source = %s\n' "${src}" >>"${conf}"

first="$(CAIRN_NOW=20261031T090000Z cairn -q -c "${conf}" snapshot)" \
  || exit 1
file="${repo}/snapshots/${first}/${src#/}/locked.txt"
before="$(stat -c '%a' "${file}")"
echo "mode in snapshot 1 before: ${before}"

echo '--- snapshot 2 with a source that does not exist ---'
printf 'source = %s\n' "${LAB_TMP}/missing" >>"${conf}"
CAIRN_NOW=20261031T100000Z cairn -q -c "${conf}" snapshot 2>/dev/null
echo "cairn snapshot exit status: $?"

after="$(stat -c '%a' "${file}")"
echo "mode in snapshot 1 after:  ${after}"
if [[ "${before}" == "${after}" ]]; then
  echo 'mode unchanged'
else
  echo 'mode CHANGED'
  exit 1
fi
echo "partial left behind: $(find "${repo}/snapshots" -name '*.partial' \
  | wc -l)"
