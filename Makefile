SCRIPT = bin/ymlmd.pl

default: \
	includes/coding-paid.md \
	includes/coding.md \
	includes/other-paid.md \
	includes/other.md

includes/%.md: data/%.yml Makefile $(SCRIPT)
	$(SCRIPT) "$<" >"$@.tmp"
	mv "$@.tmp" "$@"
