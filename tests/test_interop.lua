local interop = require("interop")

assert(interop.resolve_lua_func("math.min"))
assert(interop.resolve_lua_func("math.max"))
assert(interop.resolve_lua_func("string.len"))

assert(not interop.resolve_lua_func("non_existent"))

local res = interop.parse_signature("math.max/2")
assert(res.name == "math.max")
assert(res.arity == 2)
assert(res.void == false)

local res = interop.parse_signature("io.write~1")
assert(res.name == "io.write")
assert(res.arity == 1)
assert(res.void == true)

local res = interop.parse_signature("io.write/")
assert(res.name == "io.write")
assert(res.arity == 0)
assert(res.void == false)

local res = interop.parse_signature("io.write~")
assert(res.name == "io.write")
assert(res.arity == 0)
assert(res.void == true)
