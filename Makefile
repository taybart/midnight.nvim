# Checks queries/midnight/aerial.scm against aerial.nvim (see test/aerial/run.lua).
# AERIAL and GRAMMAR default to fresh clones in .tests/, ex. to use local ones:
#   make test-aerial AERIAL=~/.local/share/nvim/lazy/aerial.nvim GRAMMAR=../tree-sitter-midnight
AERIAL ?= .tests/aerial.nvim
GRAMMAR ?= .tests/tree-sitter-midnight
PARSER := .tests/midnight.so

.PHONY: test test-aerial update-aerial
test: test-aerial

test-aerial: $(PARSER) $(AERIAL)
	nvim --headless -u NONE -l test/aerial/run.lua $(AERIAL) $(PARSER)

# rewrite test/aerial/expected.txt from the current symbols (review the diff)
update-aerial: $(PARSER) $(AERIAL)
	nvim --headless -u NONE -l test/aerial/run.lua $(AERIAL) $(PARSER) --update

.tests/aerial.nvim:
	git clone --depth 1 https://github.com/stevearc/aerial.nvim $@

.tests/tree-sitter-midnight:
	git clone --depth 1 https://github.com/taybart/tree-sitter-midnight $@

# always rebuilt, so it follows the grammar
$(PARSER): $(GRAMMAR) FORCE
	cd $(GRAMMAR) && tree-sitter build -o $(abspath $@)

FORCE:
