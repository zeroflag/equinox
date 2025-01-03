local compiler = require("compiler")

compiler:eval_file("lib.eqx")

function assert_tos(result, code)
  local stack = compiler:eval(code)
  assert(stack:depth() == 1,
         "'" .. code .. "' depth: " .. stack:depth())
  assert(stack:tos() == result,
         "'" .. code .. "' " .. tostring(stack:tos())
         .. " <> " .. tostring(result))
  stack:pop()
end

assert_tos(2, "1 2 math.max/2")

local status, result = pcall(
  function()
    return compiler:eval("1 2 math.min")
  end)
assert(not status)
