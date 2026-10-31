ifndef CAIRN_BUSYBOX
$(error run inside nix develop)
endif

CHAPTERS := $(notdir $(wildcard lab/ch*))
SHELL_FILES = $(shell shfmt -f bin lib scripts lab tests completions install.sh 2>/dev/null)

.PHONY: chapters lint ci clean $(CHAPTERS)

$(CHAPTERS):
	bash scripts/chapter.sh $@

chapters: $(CHAPTERS)

lint:
	shellcheck $(SHELL_FILES)
	shfmt -i 2 -bn -ci -d $(SHELL_FILES)

ci: lint chapters

clean:
	rm -rf out
