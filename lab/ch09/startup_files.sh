# shellcheck shell=bash
# Shows: which startup files each way of starting bash reads. A fake HOME
# has .bash_profile, .bashrc, .profile and .bash_logout, each printing its
# own name. The matrix lists, per mode, the files that ran in order.
# The "no job control" warnings of `bash -i` without a terminal go to a
# file (setsid removes the controlling terminal, so the result does not
# depend on where the lab is started); they are listed at the end.
home="${LAB_TMP}/home"
errors="${LAB_TMP}/stderr.txt"
mkdir "${home}" || exit 1

#######################################
# Write the four startup files of the fake HOME.
#######################################
write_files() {
  local name
  for name in .bash_profile .bashrc .profile .bash_logout; do
    printf 'echo "read %s"\n' "${name}" >"${home}/${name}"
  done
}

#######################################
# Run a command in the fake HOME and print one row of the matrix.
# Arguments:
#   Row label, optional VAR=value words for the environment, command.
#######################################
run_mode() {
  local label="$1"
  shift
  local -a vars=()
  while [[ "$1" == *=* ]]; do
    vars+=("$1")
    shift
  done
  local out
  # BASH_ENV 和 ENV 取自调用者的环境, 先去掉, 免得污染结果。
  # grep 只留下文件打印的行: NixOS 的退出脚本还会输出终端标题序列。
  out="$(env -u BASH_ENV -u ENV HOME="${home}" "${vars[@]}" \
    setsid --wait "$@" 2>>"${errors}" </dev/null | grep -a '^read ')"
  printf '%-48s %s\n' "${label}" "${out//$'\n'/, }"
}

write_files
: >"${errors}"
printf '%-48s %s\n' 'command' 'files read, in order'
run_mode 'bash -l -c :' bash -l -c :
run_mode 'bash -i -c :' bash -i -c :
run_mode 'bash -c :' bash -c :
run_mode "BASH_ENV=\$HOME/.bashrc bash -c :" \
  BASH_ENV="${home}/.bashrc" bash -c :
run_mode 'bash --noprofile --norc -i -c :' \
  bash --noprofile --norc -i -c :
run_mode 'bash -l -i -c :' bash -l -i -c :
# .bash_logout 只在登录 shell 退出时读; 用 exit 退出才会走到, -c : 不会。
run_mode 'bash -l -c exit' bash -l -c exit

echo '--- login shell without .bash_profile: .profile is the fallback ---'
rm "${home}/.bash_profile"
run_mode 'bash -l -c :' bash -l -c :

echo '--- .bash_profile that sources .bashrc (the usual idiom) ---'
cat >"${home}/.bash_profile" <<'PROFILE'
echo "read .bash_profile"
if [[ -f ~/.bashrc ]]; then
  source ~/.bashrc
fi
PROFILE
run_mode 'bash -l -c :' bash -l -c :
run_mode 'bash -l -i -c :' bash -l -i -c :
run_mode 'bash -i -c :' bash -i -c :

echo '--- the real trace of bash -l -x -c : (file names masked) ---'
# 前几行来自系统的 /etc/profile 和 /etc/bashrc (NixOS 上有), 只留下载入
# 启动文件的那几行。
env -u BASH_ENV -u ENV HOME="${home}" PS4='+ ' setsid --wait \
  bash -l -x -c : 2>&1 </dev/null \
  | grep -E '^\++ (source |\. |echo .read)' | sed "s|${home}|\$HOME|"

echo '--- stderr of all runs above (job control, captured) ---'
sort "${errors}" | uniq -c
