local interop = require("interop")

assert(interop.resolve_lua_func("math.min"))
assert(interop.resolve_lua_func("math.max"))
assert(interop.resolve_lua_func("string.len"))

assert(not interop.resolve_lua_func("non_existent"))

local result

name, arity, void = interop.parse_signature("math.max/2")
assert(name == "math.max")
assert(arity == 2)
assert(void == false)

name, arity, void = interop.parse_signature("io.write!1")
assert(name == "io.write")
assert(arity == 1)
assert(void == true)
