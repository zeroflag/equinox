local utils = require("utils")

assert(utils.trim("  a bc  ") == "a bc")

local u = utils.unique({"a", "b", "a", 1, 1, 1})

assert(#u == 3)
assert(u[1] == "a")
assert(u[2] == "b")
assert(u[3] == 1)

local u = utils.keys({k1 = 1})
assert(#u == 1)
assert(u[1] == "k1")


assert(utils.startswith("abc", "a"))
assert(utils.startswith("abc", "ab"))
assert(utils.startswith("abc", "abc"))
assert(not utils.startswith("abc", "abcd"))

assert(utils.extension("a f.eqx") == ".eqx")

assert(utils.file_exists_in_any_of("repl.lua", {"src", "tests"}))
assert(not utils.file_exists_in_any_of("non_existent", {"src", "tests"}))
