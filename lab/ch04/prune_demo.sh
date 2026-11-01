# shellcheck shell=bash
# Shows: 60 snapshots of a tiny source, then `cairn -v -n prune` (only
# reports), `cairn prune` (deletes) and the snapshot count before/after.
src="${LAB_TMP}/src"
repo="${LAB_TMP}/repo"
conf="${LAB_TMP}/cairn.conf"
mkdir -p "${src}"
echo hello >"${src}/a.txt"
export TZ=UTC

cairn -c "${conf}" init "${repo}" 2>/dev/null || exit 1
printf 'source = %s\n' "${src}" >>"${conf}"
first="$(date -u -d '2026-09-02 03:00:00' +%s)"
for ((i = 0; i < 60; i++)); do
  printf -v now '%(%Y%m%dT%H%M%SZ)T' "$((first + i * 86400))"
  CAIRN_NOW="${now}" cairn -c "${conf}" snapshot >/dev/null || exit 1
done

echo "before: $(cairn -c "${conf}" list | tail -n +2 | wc -l) snapshots"
echo '--- cairn -v -n prune (first 20 lines) ---'
cairn -c "${conf}" -v -n prune | head -n 20
echo "after dry run: $(cairn -c "${conf}" list | tail -n +2 | wc -l) snapshots"
cairn -c "${conf}" prune | wc -l | xargs echo 'removed lines:'
echo "after prune: $(cairn -c "${conf}" list | tail -n +2 | wc -l) snapshots"
# list 从第 5 章起多一行表头。
cairn -c "${conf}" list | head -n 4
