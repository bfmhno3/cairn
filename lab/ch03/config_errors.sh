# shellcheck shell=bash
# Shows: one bad config per error message of the contract, each run as
# `cairn -c FILE snapshot`. Every case must exit 3 with the exact
# message. Exit 1 if any case differs.
expected_status=3
total=0
rejected=0

# check_case LABEL EXPECTED_MESSAGE CONFIG_FILE
check_case() {
  local label="$1"
  local want="$2"
  local conf="$3"
  local got status
  got="$(cairn -c "${conf}" snapshot 2>&1 >/dev/null)"
  status=$?
  ((++total))
  printf '%-16s exit %d  %s\n' "${label}" "${status}" \
    "${got//"${LAB_TMP}"/\$LAB_TMP}"
  if ((status == expected_status)) && [[ "${got}" == "${want}" ]]; then
    ((++rejected))
  else
    printf '  expected: %s\n' "${want//"${LAB_TMP}"/\$LAB_TMP}" >&2
  fi
}

# write_conf NAME LINE...: write a config file, print its path.
write_conf() {
  local file="${LAB_TMP}/$1.conf"
  shift
  printf '%s\n' "$@" >"${file}"
  printf '%s\n' "${file}"
}

repo="${LAB_TMP}/repo"
plain="${LAB_TMP}/plain"
cairn -c "${LAB_TMP}/init.conf" init "${repo}" 2>/dev/null || exit 1
mkdir "${plain}"
src="${LAB_TMP}/src"
mkdir "${src}"

conf="${LAB_TMP}/absent.conf"
check_case 'no file' \
  "cairn: error: no config file at ${conf} (run 'cairn init REPO' first)" \
  "${conf}"

conf="$(write_conf syntax 'repo = x' 'this is not a pair')"
check_case 'no equals' "cairn: error: ${conf}:2: expected 'key = value'" \
  "${conf}"

conf="$(write_conf unknown "repo = ${repo}" 'colour = blue')"
check_case 'unknown key' "cairn: error: ${conf}:2: unknown key 'colour'" \
  "${conf}"

conf="$(write_conf relative "repo = ${repo}" 'source = docs')"
check_case 'relative source' \
  "cairn: error: ${conf}:2: source must be an absolute path" "${conf}"

conf="$(write_conf notnum "repo = ${repo}" "source = ${src}" \
  'keep_daily = soon')"
check_case 'not an integer' \
  "cairn: error: ${conf}:3: keep_daily must be a non-negative integer" \
  "${conf}"

conf="$(write_conf zero "repo = ${repo}" "source = ${src}" 'keep_last = 0')"
check_case 'keep_last zero' \
  "cairn: error: ${conf}: keep_last must be at least 1" "${conf}"

conf="$(write_conf norepo "source = ${src}")"
check_case 'missing repo' \
  "cairn: error: ${conf}: missing required key 'repo'" "${conf}"

conf="$(write_conf nosource "repo = ${repo}")"
check_case 'missing source' \
  "cairn: error: ${conf}: missing required key 'source'" "${conf}"

conf="$(write_conf nomarker "repo = ${plain}" "source = ${src}")"
want="cairn: error: ${plain} is not a cairn repository"
want+=" (run 'cairn init ${plain}')"
check_case 'no repo marker' "${want}" "${conf}"

echo "rejected: ${rejected} of ${total} cases"
((rejected == total)) || exit 1
