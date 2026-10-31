# shellcheck shell=bash
# Shows: a file named -rf turns into an option when * expands to it.
# args.sh stands in for ls (and for rm, which we never run here).
export LC_ALL=C
args="${CAIRN_ROOT}/lab/ch02/args.sh"
tree="${LAB_TMP}/tree"
bash "${CAIRN_ROOT}/scripts/make_tree.sh" "${tree}" || exit 1
cd "${tree}" || exit 1
rm -r empty_dir nested link_to_plain
rm -- 'star*.txt' $'new\nline.txt'

echo '--- ls * (BAD): -rf sorts first and looks like an option'
# shellcheck disable=SC2035 # BAD: deliberate
bash "${args}" *
echo '--- ls ./*: every word starts with ./'
bash "${args}" ./*
echo '--- ls -- *: -- ends option parsing'
bash "${args}" -- *
echo '--- what real ls does with the first one'
# shellcheck disable=SC2035,SC2012 # BAD: deliberate
ls * 2>&1 | head -n 3
