# shellcheck shell=bash
# Shows: which config file wins: -c FILE, then $CAIRN_CONFIG, then
# $XDG_CONFIG_HOME/cairn/cairn.conf. Each case snapshots into the
# repository named by the config that was picked.
# Exit 1 if a case picks the wrong config.
failed=0

# make_config NAME CONFIG_FILE: a repo "repo_NAME" with its own config.
make_config() {
  mkdir -p "$(dirname -- "$2")" "${LAB_TMP}/src"
  cairn -c "$2" init "${LAB_TMP}/repo_$1" 2>/dev/null || exit 1
  printf 'source = %s\n' "${LAB_TMP}/src" >>"$2"
}

# picked NOW: print the name of the repo that got snapshot NOW.
picked() {
  local dir
  for dir in flag env xdg; do
    if [[ -d "${LAB_TMP}/repo_${dir}/snapshots/$1" ]]; then
      printf '%s\n' "${dir}"
    fi
  done
}

# run_case LABEL EXPECTED NOW CMD...
run_case() {
  local label="$1"
  local want="$2"
  local now="$3"
  shift 3
  CAIRN_NOW="${now}" "$@" >/dev/null 2>&1
  local got
  got="$(picked "${now}")"
  printf '%-34s -> repo_%s\n' "${label}" "${got}"
  if [[ "${got}" != "${want}" ]]; then
    failed=1
  fi
}

make_config flag "${LAB_TMP}/flag.conf"
make_config env "${LAB_TMP}/env.conf"
make_config xdg "${LAB_TMP}/xdg/cairn/cairn.conf"
export XDG_CONFIG_HOME="${LAB_TMP}/xdg"
unset CAIRN_CONFIG

run_case 'XDG default only' xdg 20261101T000001Z cairn snapshot
run_case 'CAIRN_CONFIG set' env 20261101T000002Z \
  env CAIRN_CONFIG="${LAB_TMP}/env.conf" cairn snapshot
run_case '-c FILE and CAIRN_CONFIG' flag 20261101T000003Z \
  env CAIRN_CONFIG="${LAB_TMP}/env.conf" \
  cairn -c "${LAB_TMP}/flag.conf" snapshot
run_case '--config FILE' flag 20261101T000004Z \
  cairn --config "${LAB_TMP}/flag.conf" snapshot
run_case '--config=FILE' flag 20261101T000005Z \
  cairn --config="${LAB_TMP}/flag.conf" snapshot
exit "${failed}"
