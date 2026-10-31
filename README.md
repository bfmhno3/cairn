# cairn

Companion code for the blog series "用 Cairn 从零学 Shell" (learning Shell from scratch by building `cairn`, an
incremental hard-link snapshot backup tool). Everything is written for Bash 5.3 (the installer in chapter 10 for POSIX
`sh`) and follows the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html), with one
deviation: the shebang is `#!/usr/bin/env bash`, because NixOS has no `/bin/bash`.

Each chapter is one git tag, `ch01` to `ch10`. Check out a tag to see the repository exactly as the post describes it.

## Chapters

| Chapter | Topic | Post |
| --- | --- | --- |
| `ch01` | Shebang, fork/exec, exit status | `/posts/shell-by-cairn-01-first-script/` |
| `ch02` | Expansion and quoting | `/posts/shell-by-cairn-02-expansion-and-quoting/` |
| `ch03` | Variables, parameter expansion, config parsing | `/posts/shell-by-cairn-03-variables-and-parameters/` |
| `ch04` | Control flow, functions, arithmetic, `prune` | `/posts/shell-by-cairn-04-control-flow-and-functions/` |
| `ch05` | Redirection, pipes, processes, hard-link snapshots | `/posts/shell-by-cairn-05-redirection-pipes-processes/` |
| `ch06` | sed, awk, `report` and `diff` | `/posts/shell-by-cairn-06-text-processing/` |
| `ch07` | `set -e`, traps, signals, locks | `/posts/shell-by-cairn-07-errors-traps-signals/` |
| `ch08` | bats, ShellCheck, shfmt, CI, systemd | `/posts/shell-by-cairn-08-testing-and-tooling/` |
| `ch09` | Interactive bash, completion | `/posts/shell-by-cairn-09-interactive-shell/` |
| `ch10` | POSIX `sh` and the installer | `/posts/shell-by-cairn-10-posix-sh/` |

The posts live at <https://bfmhno3.github.io>.

## Layout

```text
bin/cairn          the executable
lib/cairn/         libraries sourced by bin/cairn
scripts/           chapter runner (chapter.sh)
lab/chNN/          small lab scripts, one directory per chapter
```

Lab conventions, enforced by `scripts/chapter.sh`:

- Each lab runs in a fresh sandbox (`$LAB_TMP`) with `bin/` on `PATH`; stdout, stderr and the exit status go to
  `out/chNN/<name>.{stdout,stderr,status}`.
- `*_fail.sh` must exit non-zero, every other lab must exit 0.
- `*_host.sh` is skipped when `CI=true`.
- A lab that is not executable is run as `bash <file>`; an executable one is run through its shebang.

## Running

Everything runs inside the Nix dev shell, which provides Bash 5.3, ShellCheck, shfmt, bats, dash, yash, mksh,
hyperfine, strace and the other tools of the series.

```bash
nix develop
make ch01      # run the labs of one chapter
make lint      # shellcheck + shfmt
make ci        # lint + every chapter
```

## License

Licensed under either of [Apache License 2.0](LICENSE-APACHE) or [MIT license](LICENSE-MIT) at your option.
