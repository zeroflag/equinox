LUA54 = lua5.4
LUA51 = lua5.1
LUA_VERSIONS := $(LUA54) $(LUA51) lua
TEST_DIR = tests
TEST_LUA_FILES = $(wildcard $(TEST_DIR)/test_*.lua)
TEST_EQX_FILES = $(wildcard $(TEST_DIR)/test_*.eqx)
EQUINOX = equinox.lua
BUNDLE = equinox_bundle.lua
AMALG = amalg.lua

GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m

all: clean test version bundle

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
			echo "Running Equinox tests with -o0 ..."; \
			for file in $(TEST_EQX_FILES); do \
				echo " - $$file..."; \
				$$luaver $(EQUINOX) -o0 $$file || exit 1; \
			done; \
			echo "Running Equinox tests with -o1 ..."; \
			for file in $(TEST_EQX_FILES); do \
				echo " - $$file..."; \
				$$luaver $(EQUINOX) -o1 $$file || exit 1; \
			done; \
		fi; \
	done
	@echo "$(GREEN)All tests passed!$(NC)"

version:
	@echo "Increase patch version"
	lua version/version.lua

bundle:
	@echo "Creating $(BUNDLE)"
	$(AMALG) -s $(EQUINOX) compiler codegen ast_optimizer aux dict ast interop parser macros output stack_def repl stack -o $(BUNDLE)

repl:
	lua $(EQUINOX)

clean:
	@echo "Cleaning up"
	rm -f $(BUNDLE)

# Add a phony directive to prevent file conflicts
.PHONY: all test clean bundle repl version
