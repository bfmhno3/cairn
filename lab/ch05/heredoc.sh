# shellcheck shell=bash
# Shows: here-documents. An unquoted delimiter expands $var and $(cmd);
# a quoted delimiter keeps the text literal; `<<-` strips leading TABs
# (and only tabs) so the body can be indented with the code.
name='cairn'

echo '--- unquoted delimiter: expands ---'
cat <<EOT
name is ${name}
sum is $((1 + 2))
home is \$HOME (escaped)
EOT

echo '--- quoted delimiter: literal ---'
cat <<'EOT'
name is ${name}
sum is $((1 + 2))
EOT

echo '--- <<- strips leading tabs ---'
if true; then
  cat <<-EOT
	indented with a tab, printed flush left
	  two spaces after the tab survive
	EOT
fi

echo '--- plain << keeps every space and tab ---'
if true; then
  cat <<EOT
  indented with two spaces, printed as is
EOT
fi

echo '--- a here-document is a redirection: it feeds stdin ---'
wc -l <<EOT
one
two
three
EOT

echo '--- into a variable ---'
read -r -d '' text <<EOT
first
second
EOT
printf '[%s]\n' "${text}"
