local Optimizer = {}

function Optimizer.new()
  local obj = {}
  setmetatable(obj, {__index = Optimizer})
  return obj
end

--[[
# 1 5 to: i i i * . end
push: {"item":{"kind":"number","name":"literal","value":1},"name":"push"}
push: {"item":{"kind":"number","name":"literal","value":5},"name":"push"}
push: {"item":{"id":"i","name":"identifier"},"name":"push"}
push: {"item":{"id":"i","name":"identifier"},"name":"push"}
push: {"item":{"name":"bin_op","op":"*","p1":{"name":"stack_op","op":"pop"},"p2":{"name":"stack_op","op":"pop"}},"name":"push"}
1 4 9 16 25 OK
]]

function is(ast, name)
  return ast.name == name
end

function lit_push(ast)
  return is(ast, "push") and is(ast.item, "literal")
end

function id_push(ast)
  return is(ast, "push") and is(ast.item, "identifier")
end

function lit_or_id_push(ast)
  return id_push(ast) or lit_push(ast)
end

function binop_push(ast)
  return is(ast, "push") and is(ast.item, "bin_op")
end

function unop_push(ast)
  return is(ast, "push") and is(ast.item, "unary_op")
end

local binop = {lit_or_id_push, lit_or_id_push, binop_push}
local unop = {lit_or_id_push, unop_push}

function match(matcher, ast, start)
  for i, m in ipairs(matcher) do
    if not m(ast[start + i -1]) then
      return false
    end
  end
  return true
end

function Optimizer:optimize_ast(ast)
  local result = {}
  local i = 1
  while i <= #ast do
    local node = ast[i]
      require("tests/json")
      print(node.name .. ": " .. to_json_str(node))
    if match(binop, ast, i) then
      local p1 = ast[i]
      local p2 = ast[i + 1]
      local push_bin = ast[i + 2]
      push_bin.item.p1 = p1.item
      push_bin.item.p2 = p2.item
      table.insert(result, push_bin)
      i = i + #binop
    elseif match(unop, ast, i) then
      local p1 = ast[i]
      local push_un = ast[i + 1]
      push_un.item.p1 = p1.item
      table.insert(result, push_un)
      i = i + #unop
    else
      table.insert(result, node)
      i = i + 1
    end
  end
  return result
end

return Optimizer
