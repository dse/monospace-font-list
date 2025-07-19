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

coding.md: includes/coding.md includes/coding-paid.md Makefile
	( echo "# Monospace Typefaces for Coding"; echo ; \
	  echo "## Freely Available" ; echo ; \
	  cat includes/coding.md ; echo ; \
	  echo "## Paid" ; echo ; \
	  cat includes/coding-paid.md ; echo ; ) >"$@.tmp"
	mv "$@.tmp" "$@"

other.md: includes/other.md includes/other-paid.md Makefile
	( echo "# Other Monospace Typefaces"; echo ; \
	  echo "## Freely Available" ; echo ; \
	  cat includes/other.md ; echo ; \
	  echo "## Paid" ; echo ; \
	  cat includes/other-paid.md ; echo ; ) >"$@.tmp"
	mv "$@.tmp" "$@"

dupes: FORCE
	grep --no-filename '^- name:' data/{coding,other}{,-paid}.yml | \
		sort | uniq -c | sort -n | grep -v '^ *1 -'

FONT_OTFS = $(wildcard fonts/coding-fonts/*/*.otf)
FONT_TTFS = $(wildcard fonts/coding-fonts/*/*.ttf)
OTF_PREVIEWS = $(FONT_OTFS:fonts/coding-fonts/%.otf=previews/%.preview.png)
TTF_PREVIEWS = $(FONT_TTFS:fonts/coding-fonts/%.ttf=previews/%.preview.png)

previews: FORCE
	make $(OTF_PREVIEWS) $(TTF_PREVIEWS)

previews/%.preview.png: fonts/coding-fonts/%.ttf Makefile sample.txt bin/annotator
	mkdir -p "$$(dirname "$@")"
	convert -size 5120x2560 canvas:none -pointsize 128 -font "$<" \
		-gravity NorthWest -annotate +8+8 "$$(bin/annotator sample.txt)" \
		-background white -flatten \
		"$@.tmp.png"
	mv "$@.tmp.png" "$@"
	mogrify -resize 1280 "$@"

previews/%.preview.png: fonts/coding-fonts/%.otf Makefile sample.txt bin/annotator
	mkdir -p "$$(dirname "$@")"
	convert -size 5120x2560 canvas:none -pointsize 128 -font "$<" \
		-gravity NorthWest -annotate +8+8 "$$(bin/annotator sample.txt)" \
		-background white -flatten \
		"$@.tmp.png"
	mv "$@.tmp.png" "$@"
	mogrify -resize 1280 "$@"

clean: FORCE
	rm coding.md other.md $(MD_FILES) || true
	rm -fr previews || true

.PHONY: FORCE
