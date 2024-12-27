LUA = lua5.4
TEST_LUA_FILES = $(wildcard test_*.lua)
TEST_EQX_FILES = $(wildcard test_*.eqx)
EQUINOX = equinox.lua
REPL = repl.lua

ifeq ($(shell command -v $(LUA) 2>/dev/null),)
	LUA = lua
endif

# Default target
all: test

test:
	@echo "Running Lua tests..."
	@for file in $(TEST_LUA_FILES); do \
		echo "Running $$file..."; \
		$(LUA) $$file || exit 1; \
	done

	@echo "Running Equinox tests..."
	@for file in $(TEST_EQX_FILES); do \
		echo "Running $$file..."; \
		$(LUA) $(EQUINOX) $$file || exit 1; \
	done

	@echo "All tests passed!"

repl:
	$(LUA) $(REPL)

clean:
	@echo "No cleanup necessary for Lua tests."

# Add a phony directive to prevent file conflicts
.PHONY: all test clean
