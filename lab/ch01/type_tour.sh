# shellcheck shell=bash
# Shows: what `type`, `command -V` and `hash` say about common names.
# PATH is deduplicated first so that `type -a` lists each file once.
declare -A seen=()
new_path=''
IFS=: read -r -a dirs <<<"${PATH}"
for dir in "${dirs[@]}"; do
  if [[ -z "${seen[${dir}]:-}" ]]; then
    seen["${dir}"]=1
    new_path+="${new_path:+:}${dir}"
  fi
done
PATH="${new_path}"
type -a echo cd [ test printf true
echo '--- type -t'
for name in echo cd if ls ll; do
  printf '%-4s %s\n' "${name}" "$(type -t "${name}" || echo none)"
done
echo '--- command -V'
command -V cd ls
echo '--- hash'
hash -r
ls >/dev/null
ls >/dev/null
hash
