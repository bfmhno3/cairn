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
bin/cairn           the executable
install.sh         POSIX sh installer (chapter 10)
lib/cairn/*.sh     libraries sourced by bin/cairn (log, config, repo, snapshot, manifest, prune, lock)
lib/cairn/*.awk    awk programs run with awk -f (report.awk for `cairn report`, diff.awk for `cairn diff`)
completions/      bash completion for cairn (cairn.bash)
scripts/           chapter runner (chapter.sh), fixture generator (make_tree.sh)
tests/            bats suite (`*.bats`) and its helper (test_helper.bash)
contrib/systemd/  user units: cairn.service and cairn.timer (daily snapshot and prune)
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
make test      # bats suite, one job per CPU (needs GNU parallel)
make coverage  # kcov line coverage of bin/ and lib/ into out/coverage
make install   # ./install.sh --prefix "$HOME/.local" (PREFIX=DIR to change it)
make ci        # lint + every chapter + test
```

## Install

`install.sh` is plain POSIX `sh`: it runs under dash, busybox sh, yash, mksh and `bash --posix`, so it needs no
bash to start (cairn itself does need bash 5.x on `PATH`; the installer warns when it cannot find one).

```bash
./install.sh                          # into ~/.local
./install.sh --prefix /opt/cairn      # into another prefix
DESTDIR=/tmp/stage ./install.sh --prefix /usr   # staging for a package
make install PREFIX=/opt/cairn        # the same through make, inside nix develop
```

It installs these files below the prefix:

| From | To | Mode |
| --- | --- | --- |
| `bin/cairn` | `bin/cairn` | 0755 |
| `lib/cairn/*` | `lib/cairn/` | 0644 |
| `completions/cairn.bash` | `share/bash-completion/completions/cairn` | 0644 |
| `contrib/systemd/*` | `share/cairn/systemd/` | 0644 |

`bin/cairn` finds its libraries at `../lib/cairn` relative to itself, so the installed layout needs no extra setting.
Make sure `<prefix>/bin` is on `PATH`. The systemd units expect `cairn` at `~/.local/bin`: copy them from
`share/cairn/systemd/` to `~/.config/systemd/user/` and edit `ExecStart` if you chose another prefix.

To uninstall, run the same command with `--uninstall` (and the same `--prefix`/`DESTDIR`): it removes exactly the files
listed above, then removes the directories `bin`, `lib/cairn`, `lib`, `share/cairn/systemd`, `share/cairn`,
`share/bash-completion/completions`, `share/bash-completion` and `share` below the prefix if they are now empty,
including ones that existed before. Files you added yourself are left alone.

```bash
./install.sh --prefix /opt/cairn --uninstall
```

Check what is installed: `cairn --version` prints `cairn 0.1.0`. The tests are in `tests/install.bats`; they install
only into a temporary directory.

## Shell completion

`completions/cairn.bash` completes the options and commands of `cairn`, config files after `-c`/`--config`, directories
after `init`, and snapshot names after `verify` and `diff` (read from `cairn list`, using the `-c` file of the command
line if there is one). It needs bash itself, not the bash-completion package. Pick one way to enable it:

```bash
# for the current shell only
source completions/cairn.bash

# in every interactive shell: put this line in ~/.bashrc
source /path/to/cairn/completions/cairn.bash

# loaded on demand by bash-completion, the first time you press TAB after `cairn`
mkdir -p ~/.local/share/bash-completion/completions
ln -s /path/to/cairn/completions/cairn.bash ~/.local/share/bash-completion/completions/cairn
```

`install.sh` puts the file at `<prefix>/share/bash-completion/completions/cairn`, where bash-completion looks for it
when `<prefix>/share` is in its search path (`~/.local/share` is). `cairn` has to be on `PATH` for the snapshot names
to work. The tests are in `tests/completion.bats`.

## License

Licensed under either of [Apache License 2.0](LICENSE-APACHE) or [MIT license](LICENSE-MIT) at your option.
