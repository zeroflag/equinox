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

function is_lit(ast)
  return is(ast, "push") and is(ast.item, "literal")
end

function is_id(ast)
  return is(ast, "push") and is(ast.item, "identifier")
end

function is_lit_or_id(ast)
  return is_id(ast) or is_lit(ast)
end

function is_binop(ast)
  return is(ast, "push") and is(ast.item, "bin_op")
end

function is_unop(ast)
  return is(ast, "push") and is(ast.item, "unary_op")
end

function is_assignment(ast)
  return is(ast, "assignment")
end

local binop_inline_params = {is_lit_or_id, is_lit_or_id, is_binop}
local unop_inline_param = {is_lit_or_id, is_unop}
local assignment_inline_param = {is_lit_or_id, is_assignment}

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
    if match(binop_inline_params, ast, i) then
      local p1, p2, op = ast[i],  ast[i + 1], ast[i + 2]
      op.item.p1 = p1.item
      op.item.p2 = p2.item
      table.insert(result, op)
      i = i + #binop_inline_params
    elseif match(unop_inline_param, ast, i) then
      local p1, op = ast[i], ast[i + 1]
      op.item.p1 = p1.item
      table.insert(result, op)
      i = i + #unop_inline_param
    elseif match(assignment_inline_param, ast, i) then
      local p1, op = ast[i], ast[i + 1]
      op.exp = p1.item
      table.insert(result, op)
      i = i + #assignment_inline_param
    else
      table.insert(result, node)
      i = i + 1
    end
  end
  return result
end

return Optimizer
