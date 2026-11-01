# shellcheck shell=bash
# Shows: the solution of exercise 1, a bats file that tests `cairn init`
# for idempotence. Copies fixtures/ex_init.bats.txt to $LAB_TMP and runs
# it with bats; the lab exits with bats' status.
cp "${CAIRN_ROOT}/lab/ch08/fixtures/ex_init.bats.txt" \
  "${LAB_TMP}/ex_init.bats" || exit 1
echo '$ bats --tap ex_init.bats'
bats --tap "${LAB_TMP}/ex_init.bats"
status=$?
echo "bats exit status: ${status}"
exit "${status}"
