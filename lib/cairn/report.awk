# Summarise logs/cairn.log: snapshot counts, bytes, durations, per day.
#
# Usage: awk -f report.awk logs/cairn.log
#
# Reads lines of the form
#   <timestamp> <LEVEL> <EVENT> <KEY=VALUE ...>
# and looks only at EVENT "snapshot". Every such line has name= and
# status= (ok, failed or interrupted); ok lines also carry bytes= and
# seconds=. Other events (prune, ...) are ignored.
# The per-day table counts the snapshots that ended ok, by the date in
# the snapshot name (YYYYMMDDTHHMMSSZ).

# Turn a byte count into 1024-based units (1.5K, 20M) with numfmt.
function iec(n,    cmd, out) {
  cmd = "numfmt --to=iec " n
  out = ""
  cmd | getline out
  close(cmd)
  return out
}

# Split fields 4..NF at the first "=" into kv["key"] = "value".
function parse_pairs(    i, eq) {
  delete kv
  for (i = 4; i <= NF; i++) {
    eq = index($i, "=")
    if (eq > 1) {
      kv[substr($i, 1, eq - 1)] = substr($i, eq + 1)
    }
  }
}

$3 == "snapshot" {
  parse_pairs()
  total++
  status = kv["status"]
  if (status == "ok") {
    ok++
    bytes += kv["bytes"]
    secs += kv["seconds"]
    if (kv["seconds"] + 0 > max_secs) {
      max_secs = kv["seconds"] + 0
    }
    name = kv["name"]
    day = substr(name, 1, 4) "-" substr(name, 5, 2) "-" substr(name, 7, 2)
    day_count[day]++
    day_bytes[day] += kv["bytes"]
  } else if (status == "failed") {
    failed++
  } else if (status == "interrupted") {
    interrupted++
  }
}

END {
  printf "%-13s%d\n", "snapshots", total
  printf "%-13s%d\n", "ok", ok
  printf "%-13s%d\n", "failed", failed
  printf "%-13s%d\n", "interrupted", interrupted
  printf "%-13s%s\n", "bytes", iec(bytes + 0)
  printf "%-13savg %.1f max %d\n", "seconds", (ok ? secs / ok : 0), max_secs
  printf "\n%-12s%-11s%s\n", "DAY", "SNAPSHOTS", "BYTES"
  # 日期是 YYYY-MM-DD, 字符串升序就是时间升序; 用管道交给 sort。
  # sort 直接写 stdout, 所以先 fflush, 免得表头排到行的后面。
  fflush()
  for (day in day_count) {
    printf "%-12s%-11d%s\n", day, day_count[day], iec(day_bytes[day]) \
      | "LC_ALL=C sort"
  }
  close("LC_ALL=C sort")
}
