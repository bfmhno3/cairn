# shellcheck shell=bash
# Shows: case patterns are globs; | alternates, * is the default.
classify() {
  case "$1" in
    -h | --help) echo "$1: help" ;;
    --config=*) echo "$1: config, value ${1#--config=}" ;;
    -[a-z]) echo "$1: one short option" ;;
    [0-9]*) echo "$1: starts with a digit" ;;
    '') echo '(empty): empty string' ;;
    *.tmp | *.bak) echo "$1: junk file" ;;
    *) echo "$1: anything else" ;;
  esac
}

for arg in -h --help --config=a.conf -v 42abc '' notes.tmp x.bak other; do
  classify "${arg}"
done
