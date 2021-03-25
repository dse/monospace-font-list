SRC = src/monospace-font-list.yaml
TARGET = monospace-font-list.md

SCRIPT = bin/make-font-list
THIS_FILE = Makefile

SCRIPT_OPTIONS =

default: $(TARGET)

$(TARGET): $(SRC) $(SCRIPT) $(THIS_FILE)
	$(SCRIPT) $(SCRIPT_OPTIONS) $< >"$@.tmp"
	mv "$@.tmp" "$@"
