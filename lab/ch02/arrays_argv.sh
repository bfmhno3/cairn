# shellcheck shell=bash
# Shows: flags kept in a string versus kept in an array.
args="${CAIRN_ROOT}/lab/ch02/args.sh"
dest='/tmp/my backups'

echo '--- flags in a string, unquoted: the quotes inside are literal'
# shellcheck disable=SC2089 # BAD: deliberate
flags="--exclude='*.tmp' --exclude=.cache --link-dest=${dest}"
# shellcheck disable=SC2086,SC2090 # BAD: deliberate
bash "${args}" ${flags}
echo '--- flags in a string, quoted: one argument'
bash "${args}" "${flags}"
echo '--- flags in an array: one word per element'
flags=(--exclude='*.tmp' --exclude=.cache "--link-dest=${dest}")
bash "${args}" "${flags[@]}"
echo '--- building the array conditionally'
opts=(--archive)
verbose=1
if ((verbose)); then
  opts+=(--verbose)
fi
opts+=(--exclude 'a b')
bash "${args}" "${opts[@]}" src/ "${dest}/"
echo "--- empty array: \"\${opts[@]}\" vanishes, \"\${opts[*]}\" is one word"
opts=()
bash "${args}" "${opts[@]}"
bash "${args}" "${opts[*]}"
