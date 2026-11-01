# shellcheck shell=bash
# Shows: `systemd-analyze verify` on the two user units of
# contrib/systemd, with ExecStart pointing at this checkout's bin/cairn
# (the real unit expects ~/.local/bin/cairn), and
# `systemd-analyze calendar daily` for the timer expression. Host only:
# it needs systemd. Enabling the timer is not done here; on a real
# machine that is `systemctl --user enable --now cairn.timer`.
units="${LAB_TMP}/units"
mkdir "${units}" || exit 1
for unit in cairn.service cairn.timer; do
  sed "s|%h/.local/bin/cairn|${CAIRN_ROOT}/bin/cairn|" \
    "${CAIRN_ROOT}/contrib/systemd/${unit}" >"${units}/${unit}" || exit 1
done
echo '$ systemd-analyze --user verify cairn.service cairn.timer'
(cd "${units}" && systemd-analyze --user verify cairn.service cairn.timer)
status=$?
echo "verify exit status: ${status}"
echo '$ systemd-analyze calendar daily'
systemd-analyze calendar daily | grep -E '^ *(Original form|Normalized form)'
exit "${status}"
