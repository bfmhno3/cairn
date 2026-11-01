# shellcheck shell=bash
# Shows: <(cmd) expands to a /dev/fd/N path that another command can
# open; diff <(...) <(...) compares two commands' output without files.
echo '--- what <(true) expands to ---'
echo <(true)

echo '--- two substitutions, two numbers ---'
echo <(true) <(true)

echo '--- diff of two command outputs ---'
diff <(printf 'a\nb\nc\n') <(printf 'a\nx\nc\n')
echo "diff exit status: $?"

echo '--- the path is a pipe, readable once ---'
# shellcheck disable=SC2012
ls -l <(true) | awk '{print substr($1, 1, 1)}'

echo '--- compare two listings sorted differently ---'
mkdir "${LAB_TMP}/d"
touch "${LAB_TMP}/d/b" "${LAB_TMP}/d/a" "${LAB_TMP}/d/c"
# shellcheck disable=SC2012
if diff <(ls "${LAB_TMP}/d") <(ls -r "${LAB_TMP}/d" | sort); then
  echo 'same names'
fi

echo '--- >(cmd) is the output form ---'
echo hello | tee >(tr '[:lower:]' '[:upper:]' >"${LAB_TMP}/upper.txt") >/dev/null
# 等后台的 tr 写完。
sleep 0.2
cat "${LAB_TMP}/upper.txt"
