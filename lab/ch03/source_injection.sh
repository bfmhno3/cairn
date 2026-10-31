# shellcheck shell=bash
# Shows: why the config is parsed and never sourced. A config in shell
# syntax runs code when it is `source`d; cairn rejects the same text.
# Exit 1 if source does not run it or cairn does.
conf="${LAB_TMP}/evil.conf"
cat >"${conf}" <<'CONF'
# a "config" written in shell syntax
export repo=$(touch "$LAB_TMP/pwned")
CONF
export LAB_TMP

echo '--- source evil.conf'
# BAD: sourcing a config file executes whatever it contains.
# shellcheck disable=SC1090
source "${conf}"
if [[ -e "${LAB_TMP}/pwned" ]]; then
  echo 'source ran the command: pwned was created'
else
  echo 'source did not run the command' >&2
  exit 1
fi
rm -f "${LAB_TMP}/pwned"

echo '--- cairn -c evil.conf snapshot'
msg="$(cairn -c "${conf}" snapshot 2>&1)"
status=$?
echo "${msg//"${LAB_TMP}"/\$LAB_TMP}"
echo "exit status: ${status}"
if [[ -e "${LAB_TMP}/pwned" ]]; then
  echo 'cairn ran the command' >&2
  exit 1
fi
echo 'pwned does not exist: the line was data, not code'
if ((status != 3)) || [[ "${msg}" != *"2: expected 'key = value'" ]]; then
  exit 1
fi
