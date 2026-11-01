# shellcheck shell=bash
# Shows: why aliases do not belong in scripts. A non-interactive bash
# ignores them unless expand_aliases is set, and even then an alias takes
# effect only for lines read after the line that defines it: defining
# and using it on one line fails. A function has neither problem.
# Google's guide: "Aliases should be avoided in scripts; use functions."

cd "${LAB_TMP}" || exit 1

#######################################
# Write a script file from stdin, run it with bash, print its output
# and exit status.
# Arguments:
#   Label, script name.
#######################################
run_script() {
  local label="$1"
  local name="$2"
  cat >"${name}"
  echo "--- ${label} ---"
  bash "${name}" 2>&1
  echo "exit status: $?"
}

run_script 'alias without expand_aliases' s1.sh <<'SCRIPT'
alias say='echo hello'
say
SCRIPT

run_script 'expand_aliases, alias defined on an earlier line' s2.sh <<'SCRIPT'
shopt -s expand_aliases
alias say='echo hello'
say
SCRIPT

# 同一行: bash 先读完整行再执行, 执行 alias 时这一行已经解析过了。
run_script 'expand_aliases, alias defined and used on one line' s3.sh <<'SCRIPT'
shopt -s expand_aliases
alias say='echo hello'; say
SCRIPT

run_script 'the same thing as a function' s4.sh <<'SCRIPT'
say() { echo hello; }; say
SCRIPT
