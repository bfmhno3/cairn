# shellcheck shell=bash
# Shows: nullglob, failglob (in a subshell), dotglob, globstar, extglob.
export LC_ALL=C
args="${CAIRN_ROOT}/lab/ch02/args.sh"
cd "${LAB_TMP}" || exit 1
mkdir -p sub/deep
touch a.txt b.txt .hidden sub/c.txt sub/deep/d.txt

echo '--- default: no match leaves the pattern'
bash "${args}" ./*.nope
echo '--- nullglob: no match expands to nothing'
shopt -s nullglob
bash "${args}" ./*.nope
shopt -u nullglob
echo '--- failglob in a subshell: the command is not run'
(
  shopt -s failglob
  bash "${args}" ./*.nope
  echo 'not reached'
)
echo "subshell status: $?"
echo '--- default: * skips dotfiles'
bash "${args}" ./*
echo '--- dotglob: * includes dotfiles'
shopt -s dotglob
bash "${args}" ./*
shopt -u dotglob
echo '--- default: ** is just *'
bash "${args}" ./**/*.txt
echo '--- globstar: ** recurses'
shopt -s globstar
bash "${args}" ./**/*.txt
shopt -u globstar
echo '--- extglob: !(a).txt and @(a|b).txt'
shopt -s extglob
bash "${args}" ./!(a).txt
bash "${args}" ./@(a|b).txt
shopt -u extglob
