# shellcheck shell=bash
# Shows: `bash -n` parses a script without running it. The fixture
# fixtures/broken_script.txt lacks a `fi`; bash -n prints the syntax
# error and exits with status 2, and so does this lab (a _fail lab).
fixture="${CAIRN_ROOT}/lab/ch08/fixtures/broken_script.txt"
cd "$(dirname -- "${fixture}")" || exit 1
echo '$ bash -n broken_script.txt'
bash -n broken_script.txt
status=$?
echo "bash -n exit status: ${status}"
exit "${status}"
