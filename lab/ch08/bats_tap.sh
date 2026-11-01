# shellcheck shell=bash
# Shows: bats' TAP output (`bats --tap`): a plan line `1..N`, then one
# `ok`/`not ok` line per test. The lab runs tests/prune.bats, prints the
# TAP stream and then the plan line and the counts; it exits 1 if any
# test fails.
cd "${CAIRN_ROOT}" || exit 1
echo '$ bats --tap tests/prune.bats'
bats --tap tests/prune.bats >"${LAB_TMP}/prune.tap"
status=$?
cat "${LAB_TMP}/prune.tap"
plan="$(grep -m 1 -E '^1\.\.[0-9]+$' "${LAB_TMP}/prune.tap")"
passed="$(grep -c -E '^ok ' "${LAB_TMP}/prune.tap")"
failed="$(grep -c -E '^not ok ' "${LAB_TMP}/prune.tap")"
echo "plan: ${plan}, ok: ${passed}, not ok: ${failed}"
echo "bats exit status: ${status}"
exit "${status}"
