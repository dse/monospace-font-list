SRC = src/monospace-font-list.yaml
TARGET = monospace-font-list.md

SCRIPT = bin/make-font-list
THIS_FILE = Makefile

default: $(TARGET)

$(TARGET): $(SRC) $(SCRIPT) $(THIS_FILE)
	$(SCRIPT) $< >"$@.tmp"
	mv "$@.tmp" "$@"
