LUA = lua5.4
TEST_FILES = $(wildcard test_*.lua)
REPL = repl.lua

ifeq ($(shell command -v $(LUA) 2>/dev/null),)
	LUA = lua
endif

# Default target
all: test

test:
	@echo "Running Lua tests..."
	@for file in $(TEST_FILES); do \
		echo "Running $$file..."; \
		$(LUA) $$file || exit 1; \
	done
	@echo "All tests passed!"

repl:
	$(LUA) $(REPL)

clean:
	@echo "No cleanup necessary for Lua tests."

# Add a phony directive to prevent file conflicts
.PHONY: all test clean
