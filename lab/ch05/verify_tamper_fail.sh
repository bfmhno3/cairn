# shellcheck shell=bash
# Shows: cairn verify notices a changed file. Make a snapshot, modify a
# file inside it (the snapshot's hard link shares data with the next one,
# so with a single snapshot only that one is affected), then verify.
# Exits 1 with a FAILED line, so this lab ends in _fail.sh.
src="${LAB_TMP}/src"
repo="${LAB_TMP}/repo"
conf="${LAB_TMP}/cairn.conf"
bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${src}" || exit 2
cairn -c "${conf}" init "${repo}" 2>/dev/null || exit 2
printf 'source = %s\n' "${src}" >>"${conf}"
name="$(CAIRN_NOW=20261031T090000Z cairn -q -c "${conf}" snapshot)" \
  || exit 2

echo '--- before tampering ---'
cairn -c "${conf}" verify || exit 2

echo '--- after appending a byte to plain.txt inside the snapshot ---'
echo x >>"${repo}/snapshots/${name}/${src#/}/plain.txt"
cairn -c "${conf}" verify
status=$?
echo "cairn verify exit status: ${status}"
exit "${status}"
