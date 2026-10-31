# shellcheck shell=bash
# Config file handling for cairn. Library: sourced by bin/cairn.
#
# The config is parsed line by line and never sourced: a config file is
# data, not code.

# 一行配置: 键, 可选空白, 等号, 可选空白, 非空的值。
readonly CAIRN_LINE_RE='^([^[:space:]=]+)[[:space:]]*=[[:space:]]*(.+)$'
# 默认值; 配置文件里的键可以覆盖它们。
readonly CAIRN_DEFAULT_KEEP_LAST=5
readonly CAIRN_DEFAULT_KEEP_DAILY=7
readonly CAIRN_DEFAULT_KEEP_WEEKLY=4

#######################################
# Print the path of the config file.
# Precedence: -c/--config, then CAIRN_CONFIG, then the XDG default.
# Globals:
#   CAIRN_CONFIG_OPT, CAIRN_CONFIG, XDG_CONFIG_HOME, HOME
# Outputs:
#   Writes the path to stdout.
#######################################
cairn::config::path() {
  local default="${XDG_CONFIG_HOME:-${HOME}/.config}/cairn/cairn.conf"
  printf '%s\n' "${CAIRN_CONFIG_OPT:-${CAIRN_CONFIG:-${default}}}"
}

#######################################
# Print the config template for a new repository.
# Arguments:
#   Absolute repository directory.
# Outputs:
#   Writes the template to stdout.
#######################################
cairn::config::template() {
  cat <<EOF2
# cairn configuration: one "key = value" per line.

# Where the snapshots live (required, once).
repo = $1

# A directory to back up (required, repeatable, absolute path).
# source = /home/you/Documents

# An rsync exclude pattern (optional, repeatable).
# exclude = *.tmp

# How many of the newest snapshots to keep (at least 1).
keep_last = ${CAIRN_DEFAULT_KEEP_LAST}

# How many days to keep one snapshot of (0 disables).
keep_daily = ${CAIRN_DEFAULT_KEEP_DAILY}

# How many weeks to keep one snapshot of (0 disables).
keep_weekly = ${CAIRN_DEFAULT_KEEP_WEEKLY}
EOF2
}

#######################################
# Parse a config file and publish its values as readonly globals.
# Globals:
#   CAIRN_REPO, CAIRN_SOURCES, CAIRN_EXCLUDES, CAIRN_KEEP_LAST,
#   CAIRN_KEEP_DAILY, CAIRN_KEEP_WEEKLY (all set and made readonly)
# Arguments:
#   Config file path.
# Outputs:
#   Writes error messages to stderr.
# Returns:
#   0 on success, 3 on a missing or invalid config.
#######################################
# shellcheck disable=SC2034 # the globals are used by the other libraries
cairn::config::load() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    cairn::log::err "no config file at ${file} (run 'cairn init REPO' first)"
    return 3
  fi

  local repo=''
  local keep_last="${CAIRN_DEFAULT_KEEP_LAST}"
  local keep_daily="${CAIRN_DEFAULT_KEEP_DAILY}"
  local keep_weekly="${CAIRN_DEFAULT_KEEP_WEEKLY}"
  local -a sources=()
  local -a excludes=()
  local line key value
  local n=0
  while IFS= read -r line || [[ -n "${line}" ]]; do
    ((++n))
    # 去掉首尾空白, 全部用参数展开, 不起子进程。
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [[ -z "${line}" || "${line}" == '#'* ]]; then
      continue
    fi
    if [[ ! "${line}" =~ ${CAIRN_LINE_RE} ]]; then
      cairn::log::err "${file}:${n}: expected 'key = value'"
      return 3
    fi
    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"
    if [[ "${value}" =~ ^~/(.*)$ ]]; then
      value="${HOME}/${BASH_REMATCH[1]}"
    fi
    case "${key}" in
      repo)
        if [[ -n "${repo}" ]]; then
          cairn::log::err "${file}:${n}: repo given more than once"
          return 3
        fi
        repo="${value}"
        ;;
      source)
        if [[ "${value}" != /* ]]; then
          cairn::log::err "${file}:${n}: source must be an absolute path"
          return 3
        fi
        sources+=("${value}")
        ;;
      exclude) excludes+=("${value}") ;;
      keep_last | keep_daily | keep_weekly)
        if [[ ! "${value}" =~ ^[0-9]{1,9}$ ]]; then
          cairn::log::err "${file}:${n}: ${key} must be a non-negative integer"
          return 3
        fi
        # printf -v 把结果写进名字为 ${key} 的变量, 即上面的 local。
        printf -v "${key}" '%d' "$((10#${value}))"
        ;;
      *)
        cairn::log::err "${file}:${n}: unknown key '${key}'"
        return 3
        ;;
    esac
  done <"${file}"

  if [[ -z "${repo}" ]]; then
    cairn::log::err "${file}: missing required key 'repo'"
    return 3
  fi
  if ((${#sources[@]} == 0)); then
    cairn::log::err "${file}: missing required key 'source'"
    return 3
  fi
  if ((keep_last < 1)); then
    cairn::log::err "${file}: keep_last must be at least 1"
    return 3
  fi

  CAIRN_REPO="${repo}"
  CAIRN_SOURCES=("${sources[@]}")
  CAIRN_EXCLUDES=("${excludes[@]}")
  CAIRN_KEEP_LAST="${keep_last}"
  CAIRN_KEEP_DAILY="${keep_daily}"
  CAIRN_KEEP_WEEKLY="${keep_weekly}"
  readonly CAIRN_REPO CAIRN_SOURCES CAIRN_EXCLUDES
  readonly CAIRN_KEEP_LAST CAIRN_KEEP_DAILY CAIRN_KEEP_WEEKLY
}
