# Compare two sha256sum manifests, print one A/D/M line per difference.
#
# Usage: awk -f diff.awk OLD.sha256 NEW.sha256
#
# Output lines (unsorted): "A <path>" added, "D <path>" deleted,
# "M <path>" modified (same path, different hash).
#
# A manifest line is parsed by position, not by fields, because a path
# may contain spaces. sha256sum prints "<64 hex>  <path>" (two blanks);
# when the path has a backslash or newline it prints "\<64 hex>  <path>"
# with the path escaped, one character further right.

function parse(line,    skip) {
  skip = (substr(line, 1, 1) == "\\") ? 1 : 0
  hash = substr(line, 1 + skip, 64)
  path = substr(line, 67 + skip)
}

# 第一个文件 (FNR == NR): 记下每个路径的哈希。
FNR == NR {
  parse($0)
  old[path] = hash
  next
}

# 第二个文件: 逐行和旧表对照。
{
  parse($0)
  seen[path] = 1
  if (!(path in old)) {
    print "A " path
  } else if (old[path] != hash) {
    print "M " path
  }
}

END {
  for (path in old) {
    if (!(path in seen)) {
      print "D " path
    }
  }
}
