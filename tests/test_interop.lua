local interop = require("interop")

assert(interop.resolve_lua_func("math.min"))
assert(interop.resolve_lua_func("math.max"))
assert(interop.resolve_lua_func("string.len"))

assert(not interop.resolve_lua_func("non_existent"))
