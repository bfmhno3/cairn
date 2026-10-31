# shellcheck shell=bash disable=SC2016,SC2034
# Shows: every parameter expansion operator on one path, as a table.
# SC2016 is off: the expressions are printed literally on purpose;
# SC2034 is off: ${!cfg_*} reads the variables indirectly.
row() {
  printf '%-26s %s\n' "$1" "$2"
}

path=/home/me/docs/report.final.tar.gz
ref=path
cfg_alpha=1
cfg_beta=2
other=3
name_with_quote="it's"

printf '%-26s %s\n' EXPRESSION RESULT
row 'path' "${path}"
row '${path#*/}' "${path#*/}"
row '${path##*/}' "${path##*/}"
row '${path%.*}' "${path%.*}"
row '${path%%.*}' "${path%%.*}"
row '${path/me/you}' "${path/me/you}"
row '${path//o/0}' "${path//o/0}"
row '${path/#\/home/HOME}' "${path/#\/home/HOME}"
row '${path/%gz/zip}' "${path/%gz/zip}"
row '${path^^}' "${path^^}"
upper="${path^^}"
row '${upper,,}' "${upper,,}"
row '${path:0:5}' "${path:0:5}"
row '${path: -9}' "${path: -9}"
row '${path:6:2}' "${path:6:2}"
row '${#path}' "${#path}"
row '${!cfg_*}' "${!cfg_*}"
row '${!ref}' "${!ref}"
row '${path@Q}' "${path@Q}"
row '${name_with_quote@Q}' "${name_with_quote@Q}"
