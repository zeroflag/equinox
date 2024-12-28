LUA54 = lua5.4
LUA51 = lua5.1
LUA_VERSIONS := $(LUA54) $(LUA51) lua
TEST_LUA_FILES = $(wildcard test_*.lua)
TEST_EQX_FILES = $(wildcard test_*.eqx)
EQUINOX = equinox.lua
BUNDLE = equinox_bundle.lua
AMALG = amalg.lua

all: clean test bundle

test:
	@for luaver in $(LUA_VERSIONS); do \
		echo "* $$luaver"; \
		if ! command -v $$luaver > /dev/null 2>&1; then \
			echo "$$luaver is not installed skippping"; \
		else \
			echo "Running Lua tests ..."; \
			for file in $(TEST_LUA_FILES); do \
				echo " - $$file..."; \
				$$luaver $$file || exit 1; \
			done; \
			echo "Running Equinox tests ..."; \
			for file in $(TEST_EQX_FILES); do \
				echo " - $$file..."; \
				$$luaver $(EQUINOX) $$file || exit 1; \
			done; \
		fi; \
  done
	@echo "All tests passed!"

bundle:
	@echo "Creating $(BUNDLE)"
	$(AMALG) -s $(EQUINOX) compiler aux dict err interop input macros ops output stack_def repl stack -o $(BUNDLE)

repl:
	lua $(EQUINOX)

clean:
	@echo "Cleaning up"
	rm -f $(BUNDLE)

# Add a phony directive to prevent file conflicts
.PHONY: all test clean
