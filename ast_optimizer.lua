local Optimizer = {}

function Optimizer.new()
  local obj = {}
  setmetatable(obj, {__index = Optimizer})
  return obj
end

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

function is_tbl_at(ast)
  return is(ast, "table_at") -- no push here
end

function is_assignment(ast)
  return is(ast, "assignment")
end

local tbl_at_inline_params = {is_lit_or_id, is_lit_or_id, is_tbl_at}
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
    -- tbl const/var at
    if match(tbl_at_inline_params, ast, i) then
      local tbl, idx, op = ast[i], ast[i + 1], ast[i + 2]
      op.tbl = tbl.item
      op.key = idx.item
      table.insert(result, op)
      i = i + #tbl_at_inline_params
    -- const/var const/var OP
    elseif match(binop_inline_params, ast, i) then
      local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
      op.item.p1 = p1.item
      op.item.p2 = p2.item
      table.insert(result, op)
      i = i + #binop_inline_params
    -- const/var OP
    elseif match(unop_inline_param, ast, i) then
      local p1, op = ast[i], ast[i + 1]
      op.item.p1 = p1.item
      table.insert(result, op)
      i = i + #unop_inline_param
    -- const/var -> VAR
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
