# shellcheck shell=bash
# Shows: readline's key bindings, counted and listed with `bind -p` in an
# interactive bash. Readline is only active in interactive shells: `bash
# -c 'bind -p'` still prints the table (about 500 lines) but warns "bind:
# warning: line editing not enabled" on stderr. The interactive bash runs
# under setsid(1): without a controlling terminal the output is the same
# whether or not the lab is started from a terminal. The count depends on
# /etc/inputrc and on the readline version; HOME is a fake directory, so
# ~/.inputrc is mine: first none, then one that rebinds the up arrow.
# Readline reads $INPUTRC, else ~/.inputrc, else /etc/inputrc: a
# ~/.inputrc replaces the system file, which is why the count changes in
# the last step.
home="${LAB_TMP}/home"
mkdir "${home}" || exit 1

#######################################
# Run `bind` arguments in an interactive bash with the fake HOME.
# Arguments:
#   The bind command line, one string.
#######################################
bind_in_bash() {
  env -u INPUTRC HOME="${home}" setsid --wait bash --norc -i -c "$1" \
    2>/dev/null
}

echo '--- how many lines does bind -p print? ---'
echo "bash -i -c 'bind -p' 2>/dev/null | wc -l"
bind_in_bash 'bind -p' | wc -l
echo 'of which bound to a function (not starting with #):'
bind_in_bash 'bind -p' | grep -vc '^#'
echo 'of which commented out (function without a key):'
bind_in_bash 'bind -p' | grep -c '^#'

echo '--- a few bindings (emacs mode, the default) ---'
bind_in_bash 'bind -p' | grep -E \
  -e '^"\\C-(a|e|r|w)":' \
  -e '^"\\e\[A":' \
  -e '^"\\e\\C-\?":'
echo '--- which keys call a function (bind -q) ---'
bind_in_bash 'bind -q reverse-search-history; bind -q clear-screen'

echo '--- the same lines with ~/.inputrc ---'
cat >"${home}/.inputrc" <<'INPUTRC'
# 上箭头改成按已输入的前缀搜索历史；关掉响铃。
"\e[A": history-search-backward
set bell-style none
INPUTRC
cat "${home}/.inputrc"
bind_in_bash 'bind -p' | grep -E '^"\\e\[A":'
bind_in_bash 'bind -v' | grep bell-style
echo 'lines of bind -p with that ~/.inputrc:'
bind_in_bash 'bind -p' | wc -l
