SCRIPT = bin/ymlmd.pl

MD_FILES := \
	includes/coding-paid.md \
	includes/coding.md \
	includes/other-paid.md \
	includes/other.md

default: coding.md other.md

includes/%.md: data/%.yml Makefile $(SCRIPT)
	$(SCRIPT) "$<" >"$@.tmp"
	mv "$@.tmp" "$@"

coding.md: $(MD_FILES)
	( echo "# Monospace Typefaces for Coding"; echo ; \
	  echo "## Freely Available" ; echo ; \
	  cat includes/coding.md ; echo ; \
	  echo "## Paid" ; echo ; \
	  cat includes/coding-paid.md ; echo ; ) >"$@.tmp"
	mv "$@.tmp" "$@"

other.md: $(MD_FILES)
	( echo "# Other Monospace Typefaces"; echo ; \
	  echo "## Freely Available" ; echo ; \
	  cat includes/other.md ; echo ; \
	  echo "## Paid" ; echo ; \
	  cat includes/other-paid.md ; echo ; ) >"$@.tmp"
	mv "$@.tmp" "$@"

clean:
	rm coding.md other.md $(MD_FILES) || true

dupes: FORCE
	grep --no-filename '^- name:' data/{coding,other}{,-paid}.yml | \
		sort | uniq -c | sort -n | grep -v '^ *1 -'

.PHONY: FORCE
