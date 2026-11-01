# shellcheck shell=bash
# Shows: cairn::prune::select 3 7 4 on 60 daily snapshots (2026-09-02 to
# 2026-10-31, 03:00 UTC). Compares the decision list with the expected
# one below and prints how many are kept, removed and why.
# Exit 1 on mismatch.
export TZ=UTC
source "${CAIRN_ROOT}/lib/cairn/prune.sh"

expected="$(
  cat <<'LIST'
keep 20261031T030000Z last
keep 20261030T030000Z last
keep 20261029T030000Z last
keep 20261028T030000Z daily
keep 20261027T030000Z daily
keep 20261026T030000Z daily
keep 20261025T030000Z daily
keep 20261024T030000Z daily
keep 20261023T030000Z daily
keep 20261022T030000Z daily
keep 20261021T030000Z weekly
remove 20261020T030000Z
remove 20261019T030000Z
keep 20261018T030000Z weekly
remove 20261017T030000Z
remove 20261016T030000Z
remove 20261015T030000Z
remove 20261014T030000Z
remove 20261013T030000Z
remove 20261012T030000Z
keep 20261011T030000Z weekly
remove 20261010T030000Z
remove 20261009T030000Z
remove 20261008T030000Z
remove 20261007T030000Z
remove 20261006T030000Z
remove 20261005T030000Z
keep 20261004T030000Z weekly
remove 20261003T030000Z
remove 20261002T030000Z
remove 20261001T030000Z
remove 20260930T030000Z
remove 20260929T030000Z
remove 20260928T030000Z
remove 20260927T030000Z
remove 20260926T030000Z
remove 20260925T030000Z
remove 20260924T030000Z
remove 20260923T030000Z
remove 20260922T030000Z
remove 20260921T030000Z
remove 20260920T030000Z
remove 20260919T030000Z
remove 20260918T030000Z
remove 20260917T030000Z
remove 20260916T030000Z
remove 20260915T030000Z
remove 20260914T030000Z
remove 20260913T030000Z
remove 20260912T030000Z
remove 20260911T030000Z
remove 20260910T030000Z
remove 20260909T030000Z
remove 20260908T030000Z
remove 20260907T030000Z
remove 20260906T030000Z
remove 20260905T030000Z
remove 20260904T030000Z
remove 20260903T030000Z
remove 20260902T030000Z
LIST
)"

first="$(date -u -d '2026-09-02 03:00:00' +%s)"
names=()
for ((i = 0; i < 60; i++)); do
  printf -v name '%(%Y%m%dT%H%M%SZ)T' "$((first + i * 86400))"
  names+=("${name}")
done

actual="$(cairn::prune::select 3 7 4 "${names[@]}")" || exit 1
echo "names: ${#names[@]}"
for kind in last daily weekly; do
  echo "keep ${kind}: $(grep -c " ${kind}\$" <<<"${actual}")"
done
echo "keep total: $(grep -c '^keep' <<<"${actual}")"
echo "remove: $(grep -c '^remove' <<<"${actual}")"

if [[ "${actual}" != "${expected}" ]]; then
  echo 'MISMATCH' >&2
  diff <(echo "${expected}") <(echo "${actual}") >&2
  exit 1
fi
echo 'matches the expected list'
