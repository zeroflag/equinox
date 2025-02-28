LUA54 = lua5.4
LUA51 = lua5.1
LUA_VERSIONS := $(LUA54) $(LUA51) luajit lua
SRC_DIR = src
TEST_DIR = tests
TEST_LUA_FILES = $(wildcard $(TEST_DIR)/test_*.lua)
TEST_EQX_FILES = $(wildcard $(TEST_DIR)/test_*.eqx)
TEST_SOUT_FILES = $(wildcard $(TEST_DIR)/sout/*.eqx)
EQUINOX = $(SRC_DIR)/equinox.lua
BUNDLE = $(SRC_DIR)/equinox_bundle.lua
AMALG = amalg.lua
luaver ?= lua
opt ?= o1

GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m

GET_VERSION = version=$$(cat $(SRC_DIR)/version/version.txt)

LUA_PATH := $(SRC_DIR)/?.lua;$(TEST_DIR)/?.lua;;$(LUA_PATH)
export LUA_PATH

all: clean test version bundle rockspec

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
		$$luaver $(EQUINOX) $(opt) $$file 2>&1 | head -n 6 | sed -E 's/\([0-9]+\)//g' > "$$file.out" || exit 1; \
		diff "$$file.out" "$$file.expected" || exit 1; \
	done

opt_tests:
	@echo "Running optimizer tests ($(luaver))"; \
	$$luaver $(EQUINOX) -od "tests/test_optimizer.eqx" > "tests/opt.out" || exit 1; \
	diff "tests/opt.out" "tests/opt.expected" || exit 1; \

test:
	@for luaver in $(LUA_VERSIONS); do \
		if ! command -v $$luaver > /dev/null 2>&1; then \
			echo "$$luaver is not installed skippping"; \
		else \
			echo "* $$luaver @ $$(which $$luaver)"; \
			luacmd="$$luaver"; \
			if [ "$$coverage" = "true" ]; then \
				if "$$luaver" -e 'require("luacov")' >/dev/null 2>&1; then \
					echo "luacov is installed"; \
					luacmd="$$luaver -lluacov"; \
				else \
					echo "luacov is NOT installed"; \
				fi ; \
			fi ; \
			$(MAKE) -s lua_tests luaver="$$luacmd" || exit 1; \
			$(MAKE) -s eqx_tests luaver="$$luacmd" opt=-o0 || exit 1; \
			$(MAKE) -s eqx_tests luaver="$$luacmd" opt=-o1 || exit 1; \
			$(MAKE) -s out_tests luaver="$$luacmd" opt=-o0 || exit 1; \
			$(MAKE) -s out_tests luaver="$$luacmd" opt=-o1 || exit 1; \
			$(MAKE) -s opt_tests luaver="$$luacmd" || exit 1; \
		fi; \
	done ;
	@echo "$(GREEN)All tests passed!$(NC)"

coverage:
	@export ENABLE_COV="true"; \
	$(MAKE) -s test coverage="true" || exit 1; \

version:
	@echo "Increase patch version" ; \
	lua $(SRC_DIR)/version/version.lua ; \

bundle:
	@$(GET_VERSION) ; \
	echo "Creating $(BUNDLE) v$${version}" ; \
	$(AMALG) -s $(EQUINOX) compiler utils console ln_repl_backend simple_repl_backend env codegen ast_optimizer ast_matchers stack_aux dict ast line_mapping interop parser macros source output repl stack -o $(BUNDLE); \
	sed -i "s/^__VERSION__=.*$$/__VERSION__=\"$${version}\"/" $(BUNDLE); \

repl:
	@lua $(shell [ "$(coverage)" = "true" ] && echo "-lluacov" || echo "") $(EQUINOX); \

rockspec:
	@$(GET_VERSION) ; \
  specfile="equinox-$${version}.rockspec" ; \
	echo "Creating rockspec: $${specfile} for v$${version}.." ; \
	cp rockspec/equinox-template.rockspec $${specfile} ; \
	sed -i "s/^version =.*$$/version = \"$$version\"/" $${specfile} ; \
	sed -i "s/\s*tag =.*$$/  tag = \"v$$version\"/" $${specfile} ; \

install:
	@$(GET_VERSION) ; \
  specfile="equinox-$${version}.rockspec" ; \
	luarocks make $${specfile} ; \

clean:
	@echo "Cleaning up" ; \
  rm equinox-*.*-*.rockspec ; \
	rm -f $(BUNDLE) ; \

# Add a phony directive to prevent file conflicts
.PHONY: all test clean bundle rockspec repl version lua_tests eqx_tests opt_tests out_tests install coverage
