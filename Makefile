default: monospace-font-list.md

monospace-font-list.md: monospace-font-list.yaml bin/make-font-list Makefile
	bin/make-font-list $< >"$@.tmp"
	mv "$@.tmp" "$@"
