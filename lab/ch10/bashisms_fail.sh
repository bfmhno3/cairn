# shellcheck shell=bash
# Shows: which bashisms break under dash. fixtures/bashisms.txt has one
# construct per line; each line is run under bash (the reference) and under
# dash, and the lab says whether dash agrees. It exits 1 on purpose: the
# constructs break. ($'..' does not: dash 0.5.13 accepts it, and POSIX.1-2024
# added it.)
fixture="${CAIRN_ROOT}/lab/ch10/fixtures/bashisms.txt"
broken=0
total=0
while IFS= read -r line; do
  [[ "${line}" == '#'* ]] && continue
  name="${line##*# }"
  total=$((total + 1))
  want="$(bash -c "${line}" 2>&1)"
  got="$(dash -c "${line}" 2>&1)"
  want="${want//$'\t'/<TAB>}"
  got="${got//$'\t'/<TAB>}"
  if [[ "${got}" == "${want}" ]]; then
    printf 'same    %s\n' "${name}"
  else
    broken=$((broken + 1))
    printf 'BREAKS  %-17s bash: %-9s dash: %s\n' "${name}" \
      "${want}" "${got##*: }"
  fi
done <"${fixture}"
echo "${broken} of ${total} constructs break under dash"
((broken == 0))
