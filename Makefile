LUA54 = lua5.4
LUA51 = lua5.1
LUA_VERSIONS := $(LUA54) $(LUA51) lua
TEST_DIR = tests
TEST_LUA_FILES = $(wildcard $(TEST_DIR)/test_*.lua)
TEST_EQX_FILES = $(wildcard $(TEST_DIR)/test_*.eqx)
TEST_SOUT_FILES = $(wildcard $(TEST_DIR)/sout/*.eqx)
EQUINOX = equinox.lua
BUNDLE = equinox_bundle.lua
AMALG = amalg.lua
luaver ?= lua
opt ?= o1

GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m

all: clean test version bundle

lua_tests:
	@echo "Running Lua tests ($(luaver))"; \
	for file in $(TEST_LUA_FILES); do \
		echo " - $$file..."; \
		$$luaver $$file || exit 1; \
	done

eqx_tests:
	@echo "Running EQX tests ($(luaver)) ($(opt))"; \
	for file in $(TEST_EQX_FILES); do \
		echo " - $$file..."; \
		$$luaver $(EQUINOX) $(opt) $$file || exit 1; \
	done

out_tests:
	@echo "Running OUT tests ($(luaver)) ($(opt))"; \
	for file in $(TEST_SOUT_FILES); do \
		echo " - $$file..."; \
		$$luaver $(EQUINOX) $(opt) $$file 2>/dev/null | sed '/Original Error:/Q' > "$$file.out" || exit 1; \
		diff "$$file.out" "$$file.expected" || exit 1; \
	done

opt_tests:
	@echo "Running optimizer tests"; \
	$$luaver $(EQUINOX) -od "tests/test_optimizer.eqx" > "tests/opt.out" || exit 1; \
	diff "tests/opt.out" "tests/opt.expected" || exit 1; \

test:
	@for luaver in $(LUA_VERSIONS); do \
		echo "* $$luaver"; \
		if ! command -v $$luaver > /dev/null 2>&1; then \
			echo "$$luaver is not installed skippping"; \
		else \
      $(MAKE) -s lua_tests luaver=$$luaver || exit 1; \
      $(MAKE) -s eqx_tests luaver=$$luaver opt=-o0 || exit 1; \
      $(MAKE) -s eqx_tests luaver=$$luaver opt=-o1 || exit 1; \
      $(MAKE) -s out_tests luaver=$$luaver opt=-o0 || exit 1; \
      $(MAKE) -s out_tests luaver=$$luaver opt=-o1 || exit 1; \
			$(MAKE) -s opt_tests luaver=$$luaver || exit 1; \
		fi; \
	done ;
	@echo "$(GREEN)All tests passed!$(NC)"

version:
	@echo "Increase patch version"
	lua version/version.lua

bundle:
	@version=$$(cat "version/version.txt") ; \
	echo "Creating $(BUNDLE) v$$version" ; \
	$(AMALG) -s $(EQUINOX) compiler utils env codegen ast_optimizer ast_matchers aux dict ast line_mapping interop parser macros output stack_def repl stack -o $(BUNDLE); \
	sed -i "s/^__VERSION__=.*$$/__VERSION__=\"$$version\"/" $(BUNDLE); \

repl:
	@lua $(EQUINOX)

clean:
	@echo "Cleaning up"
	rm -f $(BUNDLE)

# Add a phony directive to prevent file conflicts
.PHONY: all test clean bundle repl version lua_tests eqx_tests opt_tests out_tests
