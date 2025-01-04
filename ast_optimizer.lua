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

function is_lit_or_id(ast) -- or tbl at ? TODO
  return is_id(ast) or is_lit(ast)
end

function not_lit_not_id(ast)
  return not is_lit_or_id(ast)
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

function is_tbl_put(ast)
  return is(ast, "table_put") -- no push here
end

function is_assignment(ast)
  return is(ast, "assignment")
end

function is_if(ast)
  return is(ast, "if")
end

local tbl_at_inline_params = {is_lit_or_id, is_lit_or_id, is_tbl_at}
local tbl_put_inline_params = {is_lit_or_id, is_lit_or_id, is_lit_or_id, is_tbl_put}
local binop_inline_params = {is_lit_or_id, is_lit_or_id, is_binop}
local binop_inline_param_p2 = {not_lit_not_id, is_lit_or_id, is_binop}
local unop_inline_param = {is_lit_or_id, is_unop}
local assignment_inline_param = {is_lit_or_id, is_assignment}
local if_inline_cond = {is_lit_or_id, is_if}

function match(matchers, ast, start)
  for i, matcher in ipairs(matchers) do
    if start + i -1 > #ast then return false end
    local node = ast[start + i -1]
    if not matcher(node) then
      return false
    end
  end
  return true
end

function log(node)
  require("tests/json")
  print(to_json_str(node))
end

function Optimizer:optimize_ast(ast)
  local result = {}
  local i = 1
  while i <= #ast do
    local node = ast[i]
    -- log(node)
    -- tbl const/var const/var put
    if match(tbl_put_inline_params, ast, i) then
      local tbl, key, val, op = ast[i], ast[i + 1], ast[i + 2], ast[i + 3]
      op.tbl = tbl.item
      op.key = key.item
      op.value = val.item
      table.insert(result, op)
      i = i + #tbl_put_inline_params
    -- tbl const/var at
    elseif match(tbl_at_inline_params, ast, i) then
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
    -- ? const/var OP
    elseif match(binop_inline_param_p2, ast, i) then
      local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
      op.item.p1.op = "pop" -- overwrite if it's pop2nd
      op.item.p2 = p2.item
      table.insert(result, p1)
      table.insert(result, op)
      i = i + #binop_inline_param_p2
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
    -- const/var IF
    elseif match(if_inline_cond, ast, i) then
      local cond, _if = ast[i], ast[i + 1]
      _if.cond = cond.item
      table.insert(result, _if)
      i = i + #if_inline_cond
    else
      table.insert(result, node)
      i = i + 1
    end
  end
  return result
end

return Optimizer
