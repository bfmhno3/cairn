# shellcheck shell=bash
# Shows: Bash has dynamic scope. A function sees the `local` variables
# of whoever called it, not the ones of the place where it was written.
show() {
  echo "  show sees x=${x}"
}

outer() {
  local x=outer_local
  echo 'outer: local x=outer_local, calling show'
  show
}

middle() {
  local x=middle_local
  outer
  echo "middle after outer: x=${x}"
}

x=global
echo 'top level: x=global, calling show'
show
outer
middle
echo "top level at the end: x=${x}"
