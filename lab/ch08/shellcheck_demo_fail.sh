# shellcheck shell=bash
# Shows: ShellCheck on fixtures/bad_script.txt, a script with the most
# common findings (SC2086 unquoted expansion, SC2155 declare and assign
# together, SC2164 unchecked cd, SC2045 looping over ls, SC2006
# backticks). Prints the report and the number of findings; the lab
# exits with shellcheck's own status (1), so it is a _fail lab.
cd "${CAIRN_ROOT}/lab/ch08/fixtures" || exit 1
echo '$ shellcheck --shell=bash bad_script.txt'
shellcheck --shell=bash bad_script.txt
status=$?
count="$(shellcheck --shell=bash --format=gcc bad_script.txt | wc -l)"
echo "shellcheck exit status: ${status}"
echo "findings: ${count}"
exit "${status}"
