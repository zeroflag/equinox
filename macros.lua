local stack = require("stack")
local macros = {}

local label_counter = 1

function gen_label()
  label_counter = label_counter + 1
  return "LBL" .. label_counter
end

function macros.colon(compiler)
  local alias = compiler:word()
  local name = "w_" .. string.gsub(alias, "-", "_minus_")
  compiler:defword(alias, name, false)
  compiler:emit_line("function " .. name .. "()")
end

function macros.comment(compiler)
  repeat until ")" == compiler:next()
end

function macros.single_line_comment(compiler)
  repeat until "\n" == compiler:next()
end

function macros._local(compiler)
  local alias = compiler:word()
  local name = "v_" .. alias
  compiler:defvar(alias, name)
  compiler:emit_line("local " .. name)
end

function macros.assignment(compiler)
  local alias = compiler:word()
  local name = "v_" .. alias
  compiler:emit_line(name .. " = stack.pop()")
end

function macros._if(compiler)
  local label = gen_label()
  compiler:emit_line("if not stack.pop() then goto " .. label .. " end")
  stack.push(label)
end

function macros._else(compiler)
  local label = gen_label()
  compiler:emit_line("goto " .. label)
  compiler:emit_line("::" .. stack.pop() .. "::")
  stack.push(label)
end

function macros._then(compiler)
  compiler:emit_line("::" .. stack.pop() .. "::")
end

function macros._begin(compiler)
  local label = gen_label()
  compiler:emit_line("::" .. label .. "::")
  stack.push(label)
end

function macros._until(compiler)
  local label = stack.pop()
  compiler:emit_line("if not stack.pop() then goto " .. label .. " end")
end

function macros._end(compiler)
  compiler:emit_line("end")
end

return macros
