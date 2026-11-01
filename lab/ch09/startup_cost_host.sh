# shellcheck shell=bash
# Shows: what sourcing bash-completion adds to the start of an interactive
# bash, measured with hyperfine on `bash -i -c exit`. Fake HOME with a
# .bashrc that is empty or sources bash_completion; NOSYSBASHRC=1 keeps
# NixOS's /etc/bashrc (which sources bash-completion itself) out of the
# first two rows; the third row is the system default for comparison.
# Host only: timings, and the path of the bash_completion file.
# Prints the median in ms per variant and the ratio to the empty .bashrc.
bc="${CAIRN_BASH_COMPLETION:-}"
if [[ -z "${bc}" ]]; then
  # 不在 nix develop 里时, 从 /etc/bashrc 里找系统用的那份 bash-completion。
  profile_d="$(grep -o '/nix/store/[^"]*bash-completion[^"]*/etc/profile.d' \
    /etc/bashrc 2>/dev/null | head -n 1)"
  bc="${profile_d%/etc/profile.d}/share/bash-completion/bash_completion"
fi
if [[ ! -r "${bc}" ]]; then
  echo "startup_cost_host.sh: bash_completion not found (${bc})" >&2
  exit 1
fi
echo "bash_completion: ${bc}"
echo "bash: $(bash --version | head -n 1)"

home="${LAB_TMP}/home"
mkdir "${home}" || exit 1
: >"${home}/.bashrc"
printf 'source %q\n' "${bc}" >"${LAB_TMP}/bashrc_completion"

#######################################
# Print the median run time of a command line in ms, from hyperfine.
# Arguments:
#   The command, one string.
#######################################
median_ms() {
  local json="${LAB_TMP}/hyperfine.json"
  hyperfine -N --warmup 3 --runs 20 --export-json "${json}" "$1" \
    >/dev/null 2>&1 || return 1
  jq -r '.results[0].median * 1000 | . * 100 | round / 100' "${json}"
}

without="$(median_ms "env HOME=${home} NOSYSBASHRC=1 bash -i -c exit")" \
  || exit 1
cp "${LAB_TMP}/bashrc_completion" "${home}/.bashrc"
with="$(median_ms "env HOME=${home} NOSYSBASHRC=1 bash -i -c exit")" \
  || exit 1
system="$(median_ms "env HOME=${home} bash -i -c exit")" || exit 1

printf '%-48s %8s ms\n' 'empty .bashrc (NOSYSBASHRC=1)' "${without}"
printf '%-48s %8s ms\n' '.bashrc sources bash_completion' "${with}"
printf '%-48s %8s ms\n' 'system default (/etc/bashrc, fake HOME)' "${system}"
awk -v w="${with}" -v o="${without}" \
  'BEGIN { printf "ratio with/without: %.1fx\n", w / o }'
