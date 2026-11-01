# shellcheck shell=bash
# Shows: the temp-file pattern cairn uses. `mktemp` makes a private
# (mode 600) file with an unpredictable name; an EXIT trap removes it on
# every way out; the result is moved into place with `mv` on the same
# filesystem, a rename that is atomic: readers see the old or the new
# content, never half of it.
export TMPDIR="${LAB_TMP}/tmp"
mkdir -p "${TMPDIR}"

echo '--- mktemp: private, unpredictable name ---'
f="$(mktemp)"
stat -c 'mode %a, owner-only: %A' "${f}"
rm -f -- "${f}"

echo '--- without a trap the file stays when the script fails ---'
cat >no_trap.sh <<'SCRIPT'
set -e
f="$(mktemp --tmpdir cairn-leak.XXXXXX)"
echo "${f}" >leaked
false
SCRIPT
bash no_trap.sh
status=$?
echo "script status ${status};" \
  "left behind: $(find "${TMPDIR}" -type f | wc -l) file"
rm -f -- "$(cat leaked)" leaked no_trap.sh

echo '--- with an EXIT trap it is removed, also after an error ---'
cat >with_trap.sh <<'SCRIPT'
set -e
tmp="$(mktemp -d)"
trap 'rm -rf -- "${tmp}"' EXIT
echo "$tmp" >"${TMPDIR}/where"
echo data >"${tmp}/work"
false
SCRIPT
bash with_trap.sh
status=$?
if [[ -e "$(cat "${TMPDIR}/where")" ]]; then
  answer=yes
else
  answer=no
fi
echo "script status ${status}; directory exists afterwards: ${answer}"

echo '--- atomic replace: write a temp file, then mv over the target ---'
echo old >target
before="$(stat -c %i target)"
tmp="$(mktemp "${PWD}/target.XXXXXX")"
echo new >"${tmp}"
tmp_inode="$(stat -c %i "${tmp}")"
mv -T -- "${tmp}" target
after="$(stat -c %i target)"
echo "content now: $(cat target)"
echo "inode before ${before}, temp file ${tmp_inode}, after ${after}"
if [[ "${after}" == "${tmp_inode}" ]]; then
  echo 'the target is the renamed temp file'
fi
