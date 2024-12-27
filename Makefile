LUA54 = lua5.4
LUA51 = lua5.1
LUA_VERSIONS := $(LUA54) $(LUA51)
TEST_LUA_FILES = $(wildcard test_*.lua)
TEST_EQX_FILES = $(wildcard test_*.eqx)
EQUINOX = equinox.lua
REPL = repl.lua

all: test

test:
	@for luaver in $(LUA_VERSIONS); do \
    echo ""; \
    echo "* $$luaver"; \
    if ! command -v $$luaver > /dev/null 2>&1; then \
			echo "$$luaver is not installed skippping"; \
		else \
			echo "Running Lua tests ..."; \
			for file in $(TEST_LUA_FILES); do \
				echo "Running $$file..."; \
				$$luaver $$file || exit 1; \
			done; \
			echo "Running Equinox tests ..."; \
			for file in $(TEST_EQX_FILES); do \
				echo "Running $$file..."; \
				$$luaver $(EQUINOX) $$file || exit 1; \
			done; \
		fi; \
  done

	@echo "All tests passed!"

repl:
	lua $(REPL)

clean:
	@echo "No cleanup necessary for Lua tests."

# Add a phony directive to prevent file conflicts
.PHONY: all test clean
