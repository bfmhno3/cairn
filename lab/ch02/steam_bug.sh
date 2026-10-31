# shellcheck shell=bash
# Shows: what `rm -rf "$STEAMROOT/"*` receives when STEAMROOT is empty
# (the Steam for Linux bug). args.sh is run instead of rm, so nothing is
# deleted. The count of root entries depends on the host.
export LC_ALL=C
args="${CAIRN_ROOT}/lab/ch02/args.sh"
STEAMROOT=''

echo '--- STEAMROOT empty: the pattern becomes /*'
# BAD: the unguarded form, printed only
bash "${args}" -rf "${STEAMROOT}/"*
echo '--- guarded form with :? aborts instead'
(bash "${args}" -rf "${STEAMROOT:?}/"*) 2>&1
echo "status: $?"
