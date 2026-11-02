ifndef CAIRN_BUSYBOX
$(error run inside nix develop)
endif

PREFIX ?= $(HOME)/.local
CHAPTERS := $(notdir $(wildcard lab/ch*))
SHELL_FILES = $(shell shfmt -f bin lib scripts lab tests completions install.sh 2>/dev/null) $(wildcard tests/*.bats)

.PHONY: chapters lint test coverage ci install clean $(CHAPTERS)

$(CHAPTERS):
	bash scripts/chapter.sh $@

chapters: $(CHAPTERS)

lint:
	shellcheck $(SHELL_FILES)
	shfmt -i 2 -bn -ci -d $(SHELL_FILES)
	checkbashisms install.sh

test:
	bats --jobs "$$(nproc)" tests

coverage:
	kcov --bash-parser="$$(command -v bash)" --include-path=bin,lib out/coverage bats tests

ci: lint chapters test

install:
	./install.sh --prefix "$(PREFIX)"

clean:
	rm -rf out
