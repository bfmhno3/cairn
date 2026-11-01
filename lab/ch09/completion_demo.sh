# shellcheck shell=bash
# Shows: completions/cairn.bash without a terminal. A demo repository
# with three snapshots is built, the completion file is sourced, and the
# variables bash sets during completion (COMP_WORDS, COMP_CWORD) are
# filled by hand before calling _cairn: that is what pressing TAB does.
# Exits 1 if one of the three main cases gives something unexpected.
src="${LAB_TMP}/src"
repo="${LAB_TMP}/repo"
cd "${LAB_TMP}" || exit 1
conf="${LAB_TMP}/cairn.conf"
bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${src}" || exit 1
cairn -q -c "${conf}" init "${repo}" || exit 1
printf 'source = %s\n' "${src}" >>"${conf}"
for name in 20261029T090000Z 20261030T090000Z 20261031T090000Z; do
  CAIRN_NOW="${name}" cairn -q -c "${conf}" snapshot >/dev/null || exit 1
done
export CAIRN_CONFIG="${conf}"
mkdir etc
touch etc/cairn.conf etc/other.conf

# shellcheck source=../../completions/cairn.bash
source "${CAIRN_ROOT}/completions/cairn.bash"
echo "complete -p cairn: $(complete -p cairn)"

failed=0

#######################################
# Complete a command line as if TAB were pressed on its last word.
# Arguments:
#   Expected result (space separated, sorted), then the words of the
#   command line; the last word is the one being completed.
# Globals:
#   failed
#######################################
tab() {
  local expected="$1"
  shift
  COMP_WORDS=("$@")
  COMP_CWORD=$(($# - 1))
  _cairn
  local got
  # compgen -f 按目录顺序列出, 排序后输出才稳定。
  got="$(printf '%s\n' "${COMPREPLY[@]}" | LC_ALL=C sort | paste -sd ' ')"
  printf '%-34s -> %s\n' "$*<TAB>" "${got}"
  if [[ "${got}" != "${expected}" ]]; then
    printf '  expected: %s\n' "${expected}"
    failed=1
  fi
}

tab 'verify' cairn ver
tab 'etc/cairn.conf etc/other.conf' cairn -c etc/
tab '20261029T090000Z 20261030T090000Z 20261031T090000Z' cairn verify ''
echo '--- more cases ---'
tab 'etc/other.conf' cairn --config = etc/o
tab 'etc' cairn init et
tab '20261031T090000Z' cairn diff 20261029T090000Z 20261031
tab '' cairn diff 20261029T090000Z 20261030T090000Z ''
tab '--verbose --version' cairn --v
tab '' cairn list ''

echo '--- the builtins underneath ---'
echo "compgen -W 'help init list' -- i: $(compgen -W 'help init list' -- i)"
echo "compgen -d -- e: $(compgen -d -- e)"
echo "cairn list header and rows, as the completion reads them:"
cairn list | cat -A | sed -n 1,2p
exit "${failed}"
