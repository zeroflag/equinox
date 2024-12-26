LUA = lua5.4
TEST_FILES = $(wildcard test_*.lua)

# Default target
all: test

# Run the Lua script
test:
	@echo "Running Lua tests..."
	@for file in $(TEST_FILES); do \
		echo "Running $$file..."; \
		$(LUA) $$file || exit 1; \
	done
	@echo "All tests passed!"

clean:
	@echo "No cleanup necessary for Lua tests."

# Add a phony directive to prevent file conflicts
.PHONY: all test clean
