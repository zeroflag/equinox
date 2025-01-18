local Compiler = require("compiler")
local Optimizer = require("ast_optimizer")
local CodeGen = require("codegen")
local stack = require("stack")

local compiler = Compiler.new(Optimizer.new(), CodeGen.new())

function assert_tos(result, code)
  compiler:eval(code)
  assert(stack:depth() == 1,
         "'" .. code .. "' depth: " .. stack:depth())
  assert(stack:tos() == result,
         "'" .. code .. "' " .. tostring(stack:tos())
         .. " <> " .. tostring(result))
  stack:pop()
end

assert_tos(2, "1 2 >> math.max 2")
