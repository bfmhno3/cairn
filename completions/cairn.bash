# shellcheck shell=bash
#
# Bash programmable completion for cairn.
#
# Enable it for the current shell with `source completions/cairn.bash`, for
# every shell by putting that line in ~/.bashrc, or let bash-completion load
# it on demand by installing it as
# ~/.local/share/bash-completion/completions/cairn (see the README).
# It needs nothing but bash itself: no bash-completion helpers.

#######################################
# Print the snapshot names of the repository, oldest first.
# Arguments:
#   Optional config file, passed to cairn as -c.
# Outputs:
#   One name per line; nothing when `cairn list` fails.
#######################################
_cairn_snapshot_names() {
  local -a cmd=(cairn)
  if [[ -n "${1:-}" ]]; then
    cmd+=(-c "$1")
  fi
  cmd+=(list)
  local -a lines
  readarray -t lines < <("${cmd[@]}" 2>/dev/null)
  local i
  # 第 0 行是表头 (NAME FILES SIZE)，跳过；每行第一列是快照名。
  # 名字按空白切下第一列：名字里带空格的快照不会整个补全出来，
  # 但补全也不会因此出错。
  for ((i = 1; i < ${#lines[@]}; i++)); do
    printf '%s\n' "${lines[i]%% *}"
  done
}

#######################################
# Fill COMPREPLY with the snapshot names that start with a prefix.
# The names come from the repository, so they are data: they are compared
# in a loop, never expanded (compgen -W would expand a name such as
# $(cmd) when TAB is pressed).
# Globals:
#   COMPREPLY
# Arguments:
#   The prefix, then the names.
#######################################
_cairn_reply_names() {
  local prefix="$1" name
  shift
  COMPREPLY=()
  for name in "$@"; do
    if [[ "${name}" == "${prefix}"* ]]; then
      COMPREPLY+=("${name}")
    fi
  done
}

#######################################
# Complete the arguments of cairn.
#
# The first word after the options is the command: it is completed from
# the lists below, together with the options. After -c/--config (also
# written --config=FILE) comes a file; init takes one directory; verify
# takes one snapshot name and diff two.
# Globals:
#   COMP_WORDS, COMP_CWORD, COMPREPLY
#######################################
_cairn() {
  local -r options='-c --config -n --dry-run -v --verbose -q --quiet
    -h --help --version'
  local -r commands='help init snapshot list verify diff prune report'
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD - 1]:-}"
  COMPREPLY=()

  # --config=FILE: '=' is a word break, so it is a word of its own.
  local want_file=0
  if [[ "${cur}" == = && "${prev}" == --config ]]; then
    cur=''
    want_file=1
  elif [[ "${prev}" == = && "${COMP_WORDS[COMP_CWORD - 2]:-}" == --config ]] \
    || [[ "${prev}" == -c || "${prev}" == --config ]]; then
    want_file=1
  fi
  if ((want_file == 1)); then
    compopt -o filenames 2>/dev/null || :
    readarray -t COMPREPLY < <(compgen -f -- "${cur}")
    return 0
  fi

  # 找命令词和它之后的参数个数；-c/--config 的值要跳过，并记下配置文件。
  local config='' command='' word
  local -i nargs=0 i
  for ((i = 1; i < COMP_CWORD; i++)); do
    word="${COMP_WORDS[i]}"
    if [[ -n "${command}" ]]; then
      nargs=$((nargs + 1))
      continue
    fi
    case "${word}" in
      -c | --config)
        i=$((i + 1))
        if [[ "${COMP_WORDS[i]:-}" == = ]]; then
          i=$((i + 1))
        fi
        config="${COMP_WORDS[i]:-}"
        ;;
      -*) ;;
      *) command="${word}" ;;
    esac
  done

  if [[ -z "${command}" ]]; then
    readarray -t COMPREPLY < <(compgen -W "${options} ${commands}" -- "${cur}")
    return 0
  fi

  local -a names
  case "${command}" in
    init)
      if ((nargs < 1)); then
        compopt -o filenames 2>/dev/null || :
        readarray -t COMPREPLY < <(compgen -d -- "${cur}")
      fi
      ;;
    verify)
      if ((nargs < 1)); then
        readarray -t names < <(_cairn_snapshot_names "${config}")
        _cairn_reply_names "${cur}" "${names[@]}"
      fi
      ;;
    diff)
      if ((nargs < 2)); then
        readarray -t names < <(_cairn_snapshot_names "${config}")
        _cairn_reply_names "${cur}" "${names[@]}"
      fi
      ;;
    *) ;;
  esac
  return 0
}

complete -F _cairn cairn
