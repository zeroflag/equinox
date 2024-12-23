local stack = require("stack")
local macros = {}

local label_counter = 1

function gen_label()
  label_counter = label_counter + 1
  return "LBL" .. label_counter
end

function macros.colon(compiler)
  local name = compiler:word()
  compiler:define(name, false)
  compiler:emit("function " .. name .. "()")
end

function macros._if(compiler)
  local label = gen_label()
  compiler:emit("  if not stack.pop() then goto " .. label .. " end")
  stack.push(label)
end

function macros._else(compiler)
  local label = gen_label()
  compiler:emit("  goto " .. label)
  compiler:emit("::" .. stack.pop() .. "::")
  stack.push(label)
end

function macros._then(compiler)
  compiler:emit("::" .. stack.pop() .. "::")
end

function macros._begin(compiler)
  local label = gen_label()
  compiler:emit("::" .. label .. "::")
  stack.push(label)
end

function macros._until(compiler)
  local label = stack.pop()
  compiler:emit("  if not stack.pop() then goto " .. label .. " end")
end

function macros._end(compiler)
  compiler:emit("end")
end

return macros
