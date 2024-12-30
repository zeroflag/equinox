local interop = require("interop")

assert(interop.resolve_lua_func("math.min"))
assert(interop.resolve_lua_func("math.max"))
assert(interop.resolve_lua_func("string.len"))

assert(not interop.resolve_lua_func("non_existent"))

local result

result = interop.resolve_lua_func_with_arity("math.max/2")
assert(result.name == "math.max")
assert(result.arity == 2)
assert(result.vararg == false)

function test_func(a, b, c) end
function test_func_vararg(...) end
