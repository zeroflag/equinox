local Optimizer = {}

function Optimizer.new()
  local obj = {}
  setmetatable(obj, {__index = Optimizer})
  return obj
end

function is(ast, name)
  return ast.name == name
end

function is_push_lit(ast)
  return is(ast, "push") and is(ast.item, "literal")
end

function is_push_id(ast)
  return is(ast, "push") and is(ast.item, "identifier")
end

function is_push_const(ast)
  return is_push_id(ast)
    or is_push_lit(ast)
    or is_push_tbl_at_with_const_params(ast)
end

function not_push_const(ast)
  return not is_push_const(ast)
end

function is_push_binop(ast)
  return is(ast, "push") and is(ast.item, "bin_op")
end

function is_push_unop(ast)
  return is(ast, "push") and is(ast.item, "unary_op")
end

function is_tbl_at(ast)
  return is(ast, "push") and is(ast.item, "table_at")
end

function is_push_tbl_at_with_const_params(ast)
  return is(ast, "push")
    and is(ast.item, "table_at")
    and (is(ast.item.tbl, "identifier") or is(ast.item.tbl, "literal"))
    and (is(ast.item.key, "identifier") or is(ast.item.key, "literal"))
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

local tbl_at_inline_params = {is_push_const, is_push_const, is_tbl_at}
local tbl_put_inline_params = {is_push_const, is_push_const, is_push_const, is_tbl_put}
local binop_inline_params = {is_push_const, is_push_const, is_push_binop}
local binop_inline_param_p2 = {not_push_const , is_push_const, is_push_binop}
local unop_inline_param = {is_push_const, is_push_unop}
local assignment_inline_param = {is_push_const, is_assignment}
local if_inline_cond = {is_push_const, is_if}

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

function log_ast(node)
  require("tests/json")
  print(to_json_str(node))
end

function log(txt)
  print("[OPTIMIZER] " .. txt)
end

function Optimizer:optimize_iteratively(ast)
  local num_of_optimizations, iterations = 0, 0
  repeat
    ast, num_of_optimizations = self:optimize(ast)
    iterations = iterations + 1
    log(string.format(
          "Iteration: %d finished. Number of optimizations: %d",
          iterations, num_of_optimizations))
  until num_of_optimizations == 0
  return ast
end


function Optimizer:optimize(ast)
  local result, i, num_matches = {}, 1, 0
  while i <= #ast do
    local node = ast[i]
    -- log_ast(node)
    -- tbl const/var const/var put
    if match(tbl_put_inline_params, ast, i) then
      log("inlining tbl put params")
      num_matches = num_matches + 1
      local tbl, key, val, op = ast[i], ast[i + 1], ast[i + 2], ast[i + 3]
      op.tbl = tbl.item
      op.key = key.item
      op.value = val.item
      table.insert(result, op)
      i = i + #tbl_put_inline_params
    -- tbl const/var at
    elseif match(tbl_at_inline_params, ast, i) then
      log("inlining tbl at params")
      num_matches = num_matches + 1
      local tbl, idx, op = ast[i], ast[i + 1], ast[i + 2]
      op.item.tbl = tbl.item
      op.item.key = idx.item
      table.insert(result, op)
      log_ast(op)
      i = i + #tbl_at_inline_params
    -- const/var const/var OP
    elseif match(binop_inline_params, ast, i) then
      log("inlining binary operator params")
      num_matches = num_matches + 1
      local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
      op.item.p1 = p1.item
      op.item.p2 = p2.item
      table.insert(result, op)
      i = i + #binop_inline_params
    -- ? const/var OP
    elseif match(binop_inline_param_p2, ast, i) then
      log("inlining binary operator's 2nd param")
      num_matches = num_matches + 1
      local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
      op.item.p1.op = "pop" -- overwrite if it's pop2nd
      op.item.p2 = p2.item
      table.insert(result, p1)
      table.insert(result, op)
      i = i + #binop_inline_param_p2
    -- const/var OP
    elseif match(unop_inline_param, ast, i) then
      log("inlining unary operator's param")
      num_matches = num_matches + 1
      local p1, op = ast[i], ast[i + 1]
      op.item.p1 = p1.item
      table.insert(result, op)
      i = i + #unop_inline_param
    -- const/var -> VAR
    elseif match(assignment_inline_param, ast, i) then
      log("inlining assignment operator's param")
      num_matches = num_matches + 1
      local p1, op = ast[i], ast[i + 1]
      op.exp = p1.item
      table.insert(result, op)
      i = i + #assignment_inline_param
    -- const/var IF
    elseif match(if_inline_cond, ast, i) then
      log("inlining if condition")
      num_matches = num_matches + 1
      local p1, op = ast[i], ast[i + 1]
      local cond, _if = ast[i], ast[i + 1]
      _if.cond = cond.item
      table.insert(result, _if)
      i = i + #if_inline_cond
    else
      table.insert(result, node)
      i = i + 1
    end
  end
  return result, num_matches
end

return Optimizer
