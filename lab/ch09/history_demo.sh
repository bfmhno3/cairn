# shellcheck shell=bash
# Shows: history without a terminal. Part 1: `history -s` honours
# HISTCONTROL (ignoreboth = ignorespace + ignoredups). Part 2: an
# interactive bash fed from a here-string records the commands it reads
# and writes them to HISTFILE when it exits. Part 3: HISTTIMEFORMAT on a
# history file that carries "#<epoch>" lines, with TZ=UTC so the output
# is the same everywhere. HISTFILE always lives in $LAB_TMP. The
# interactive bash of part 2 runs under setsid(1): without a controlling
# terminal the output is the same whether or not the lab is started from
# a terminal.
echo '--- 1: history -s and HISTCONTROL=ignoreboth ---'
# -c 字符串每读入一行就记一条；history -s 先删掉历史里最后一条（正是它
# 自己所在的那一行），再加参数。第一条 HISTCONTROL=ignoreboth 在设置生效
# 前读入，所以留下；重复的和以空格开头的参数不记；最后一条是 history。
bash --norc -c 'set -o history
HISTCONTROL=ignoreboth
history -s "echo one"
history -s "echo one"
history -s " echo hidden by a leading space"
history -s "echo two"
history'

echo '--- 2: HISTFILE written by an interactive shell ---'
histfile="${LAB_TMP}/hist2"
{
  echo "HISTCONTROL=ignoreboth"
  echo "echo one"
  echo "echo one"
  echo " echo hidden by a leading space"
  echo "echo two"
  echo "history"
} | HISTFILE="${histfile}" PS1='$ ' setsid --wait bash --norc -i 2>&1 \
  | grep -v -e '^bash: cannot set terminal' -e '^bash: no job control'
echo '--- the file after exit ---'
cat "${histfile}"

echo '--- 3: HISTTIMEFORMAT on a file with timestamps ---'
histfile="${LAB_TMP}/hist3"
printf '#%s\n%s\n' 1793437200 'ls -l' 1793440800 'cd /tmp' >"${histfile}"
echo 'file content:'
cat "${histfile}"
echo 'history with HISTTIMEFORMAT=%F %T (TZ=UTC):'
HISTFILE="${histfile}" TZ=UTC bash --norc -c 'set -o history
history -c; HISTTIMEFORMAT="%F %T "; history -r; history'
echo 'history without HISTTIMEFORMAT:'
HISTFILE="${histfile}" bash --norc -c 'set -o history
history -c; history -r; history'
