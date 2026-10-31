# shellcheck shell=bash
# Shows: a shebang naming a missing interpreter makes exec fail (126).
printf '#!/nonexistent/bash\necho hi\n' >"${LAB_TMP}/x"
chmod +x "${LAB_TMP}/x"
"${LAB_TMP}/x"
status=$?
echo "exit status: ${status}"
exit "${status}"
