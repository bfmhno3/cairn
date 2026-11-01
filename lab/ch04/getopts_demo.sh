# shellcheck shell=bash
# Shows: getopts handles short options only; --config is not one.
parse() {
  local OPTIND=1 opt
  while getopts ':c:nv' opt; do
    case "${opt}" in
      c) echo "  -c with value '${OPTARG}'" ;;
      n) echo '  -n' ;;
      v) echo '  -v' ;;
      :) echo "  -${OPTARG} needs an argument" ;;
      \?) echo "  unknown option -${OPTARG}" ;;
    esac
  done
  shift $((OPTIND - 1))
  echo "  rest: $*"
}

echo 'parse -n -c my.conf list'
parse -n -c my.conf list
echo 'parse -nvc my.conf list   (bundled short options)'
parse -nvc my.conf list
echo 'parse --config my.conf list'
parse --config my.conf list
echo 'parse --config=my.conf list'
parse --config=my.conf list
