# shellcheck shell=bash
# Shows: shell variables vs environment variables. A child process only
# inherits what was exported, and only a copy of it.
child_sees() {
  bash -c 'printf "child sees LAB_V=%s\n" "${LAB_V-<unset>}"'
}

LAB_V=shell_only
echo "parent sets LAB_V=${LAB_V} (not exported)"
child_sees

export LAB_V
echo '--- after export LAB_V'
child_sees

echo '--- the child changes its copy, the parent keeps its own'
bash -c 'LAB_V=changed_in_child; echo "child now: ${LAB_V}"'
echo "parent still: ${LAB_V}"

echo '--- VAR=x cmd: lives only for that one command'
LAB_P=prefix bash -c 'echo "inside:  LAB_P=${LAB_P-<unset>}"'
echo "outside: LAB_P=${LAB_P-<unset>}"

echo '--- the kernel view: /proc/<pid>/environ of a child'
LAB_P=prefix sleep 30 &
pid=$!
for _ in {1..100}; do
  if tr '\0' '\n' <"/proc/${pid}/environ" | grep -q '^LAB_P='; then
    break
  fi
  sleep 0.05
done
tr '\0' '\n' <"/proc/${pid}/environ" | grep -E '^LAB_(P|V)=' | sort
kill "${pid}"
wait "${pid}" 2>/dev/null
exit 0
