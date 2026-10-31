# shellcheck shell=bash
# Exercise solution: strip the last extension of a file name with
# parameter expansion only. A leading dot is part of the name
# (".bashrc" has no extension) and dots in directory names do not count.
strip_ext() {
  local dir=''
  local base="$1"
  if [[ "$1" == */* ]]; then
    dir="${1%/*}/"
    base="${1##*/}"
  fi
  local stem="${base%.*}"
  if [[ -z "${stem}" || "${stem}" == "${base}" ]]; then
    stem="${base}"
  fi
  printf '%s%s\n' "${dir}" "${stem}"
}

for name in report.txt archive.tar.gz .bashrc noext dir.d/file.c \
  dir.d/noext 'with space.md' /a/b.c/d; do
  printf '%-18s -> %s\n' "${name}" "$(strip_ext "${name}")"
done
