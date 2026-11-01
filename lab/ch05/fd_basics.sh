# shellcheck shell=bash
# Shows: file descriptors of a running shell (/proc/self/fd), opening one
# with `exec 3>file`, letting bash pick a free number with `{fd}>`, and
# that a child process inherits the descriptors that stay open.
echo '--- fds 0-3 of a child ls (3 is the directory ls is reading) ---'
# 0/1/2 继承自 shell, 3 是 ls 自己打开的 /proc/self/fd。
# shellcheck disable=SC2012
ls -l /proc/self/fd | awk 'NR > 1 && $9 <= 3 {print $9, $10, $11}' \
  | sed -e 's/pipe:.*/pipe/' -e 's#/proc/[0-9]*/fd#/proc/<pid>/fd#' \
    -e 's#-> /\(home\|tmp\|nix\).*#-> (a file)#'

echo '--- exec 3>file: fd 3 stays open in the shell ---'
exec 3>"${LAB_TMP}/fd3.txt"
echo 'written through fd 3' >&3
echo 'written again' >&3
exec 3>&-
cat "${LAB_TMP}/fd3.txt"

echo '--- {fd}>file: bash picks the number ---'
exec {log_fd}>"${LAB_TMP}/log_fd.txt"
echo "bash chose fd ${log_fd}"
echo 'via the variable' >&"${log_fd}"
exec {log_fd}>&-
cat "${LAB_TMP}/log_fd.txt"

echo '--- inheritance: a child sees fd 3, a closed fd is gone ---'
exec 3>"${LAB_TMP}/inherit.txt"
bash -c 'echo "child writes to inherited fd 3" >&3'
bash -c 'for n in 0 1 2 3; do [[ -e /proc/self/fd/${n} ]] && printf "%s " "${n}"; done; echo'
exec 3>&-
bash -c 'echo "after closing: writing to fd 3" >&3' 2>&1 \
  | sed 's/^bash: line [0-9]*: /bash: /'
cat "${LAB_TMP}/inherit.txt"
