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

result = interop.resolve_lua_func_with_arity("test_func")
assert(result.name == "test_func")
assert(result.arity == 3)
assert(result.vararg == false)

result = interop.resolve_lua_func_with_arity("test_func_vararg")
assert(result.name == "test_func_vararg")
assert(result.arity == 0)
assert(result.vararg == true)

result = interop.resolve_lua_func_with_arity("print")
assert(result.name == "print")
assert(result.arity == 0)
assert(result.vararg == true)
