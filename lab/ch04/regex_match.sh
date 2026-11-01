# shellcheck shell=bash
# Shows: [[ =~ ]], BASH_REMATCH, and keeping the regex in a variable.
name='20261031T090000Z'

if [[ "${name}" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})T ]]; then
  echo "whole match : ${BASH_REMATCH[0]}"
  echo "year        : ${BASH_REMATCH[1]}"
  echo "month       : ${BASH_REMATCH[2]}"
  echo "day         : ${BASH_REMATCH[3]}"
fi

# 正则放进变量: 不加引号, 空白和特殊字符不会被 shell 再解释。
re='^[0-9]{8}T[0-9]{6}Z$'
if [[ "${name}" =~ ${re} ]]; then
  echo 'variable regex: match'
fi

# 加引号后右边变成字面量。
# BAD: quoted RHS.
# shellcheck disable=SC2076
if [[ "${name}" =~ "${re}" ]]; then
  echo 'quoted regex: match'
else
  echo 'quoted regex: no match (taken literally)'
fi
