local Compiler = require("compiler")
local Optimizer = require("ast_optimizer")
local CodeGen = require("codegen")
local stack = require("stack")

local compiler = Compiler:new(Optimizer:new(), CodeGen:new())

function assert_tos(result, code)
  compiler:eval_text(code)
  assert(depth() == 1,
         "'" .. code .. "' depth: " .. depth())
  assert(tos() == result,
         "'" .. code .. "' " .. tostring(tos())
         .. " <> " .. tostring(result))
  pop()
end

assert_tos(2, "1 2 #( math.max 2 )")
