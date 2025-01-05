local AstMatcher = {}

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
  return is(ast, "push")
    and is(ast.item, "bin_op")
    and is(ast.item.p1, "stack_access")
    and is(ast.item.p2, "stack_access")
end

function is_push_unop(ast)
  return is(ast, "push")
    and is(ast.item, "unary_op")
    and is(ast.item.p1, "stack_access")
end

function is_tbl_at(ast)
  return is(ast, "push")
    and is(ast.item, "table_at")
    and is(ast.item.tbl, "stack_access")
    and is(ast.item.key, "stack_access")
end

function is_push_tbl_at_with_const_params(ast)
  return is(ast, "push")
    and is(ast.item, "table_at")
    and (is(ast.item.tbl, "identifier") or is(ast.item.tbl, "literal"))
    and (is(ast.item.key, "identifier") or is(ast.item.key, "literal"))
end

function is_tbl_put(ast)
  return is(ast, "table_put") -- no push here
    and is(ast.tbl, "stack_access")
    and is(ast.key, "stack_access")
end

function is_assignment(ast)
  return is(ast, "assignment") and is(ast.exp, "stack_access")
end

function is_if(ast)
  return is(ast, "if") and is(ast.cond, "stack_access")
end

function AstMatcher:new(name, parts)
  local obj = {name = name, parts = parts}
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function AstMatcher:matches(ast, start)
  for i, matcher in ipairs(self.parts) do
    if start + i -1 > #ast then return false end
    local node = ast[start + i -1]
    if not matcher(node) then
      return false
    end
  end
  return true
end

function AstMatcher:optimize(ast, i, result)
  error("not implemented")
end

function AstMatcher:log(message)
  print("[OPTI] " .. message)
end

function AstMatcher:size()
  return #self.parts
end

AtParamsInline = AstMatcher:new()
PutParamsInline = AstMatcher:new()
IfCondInline = AstMatcher:new()
AssignmentInline = AstMatcher:new()
UnaryInline = AstMatcher:new()
BinaryInline = AstMatcher:new()
BinaryInlineP2 = AstMatcher:new()

function AtParamsInline:optimize(ast, i, result, logging)
  if logging then
  self:log("inlining tbl at params")
  end
  local tbl, idx, op = ast[i], ast[i + 1], ast[i + 2]
  op.item.tbl = tbl.item
  op.item.key = idx.item
  table.insert(result, op)
end

function PutParamsInline:optimize(ast, i, result, logging)
  if logging then
  self:log("inlining tbl put params")
  end
  local tbl, key, val, op = ast[i], ast[i + 1], ast[i + 2], ast[i + 3]
  op.tbl = tbl.item
  op.key = key.item
  op.value = val.item
  table.insert(result, op)
end

function IfCondInline:optimize(ast, i, result, logging)
  if logging then
  self:log("inlining if condition")
  end
  local p1, op = ast[i], ast[i + 1]
  local cond, _if = ast[i], ast[i + 1]
  _if.cond = cond.item
  table.insert(result, _if)
end

function AssignmentInline:optimize(ast, i, result, logging)
  if logging then
  self:log("inlining assignment operator's param")
  end
  local p1, op = ast[i], ast[i + 1]
  op.exp = p1.item
  table.insert(result, op)
end

function UnaryInline:optimize(ast, i, result, logging)
  if logging then
  self:log("inlining unary operator's param")
  end
  local p1, op = ast[i], ast[i + 1]
  op.item.p1 = p1.item
  table.insert(result, op)
end

function BinaryInline:optimize(ast, i, result, logging)
  if logging then
  self:log("inlining binary operator params")
  end
  local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
  op.item.p1 = p1.item
  op.item.p2 = p2.item
  table.insert(result, op)
end

function BinaryInlineP2:optimize(ast, i, result, logging)
  if logging then
  self:log("inlining binary operator's 2nd param")
  end
  local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
  if op.item.p1.op == "pop2nd" then op.item.p1.op = "pop" end
  op.item.p2 = p2.item
  table.insert(result, p1)
  table.insert(result, op)
end

return {
  PutParamsInline:new(
    "inline put params ",
    {is_push_const, is_push_const, is_push_const, is_tbl_put}),

  AtParamsInline:new(
    "inline at params",
    {is_push_const, is_push_const, is_tbl_at}),

  BinaryInline:new(
    "binary inline",
    {is_push_const, is_push_const, is_push_binop}),

  BinaryInlineP2:new(
    "binary p2 inline",
    {not_push_const , is_push_const, is_push_binop}),

  UnaryInline:new(
    "unary inline",
    {is_push_const, is_push_unop}),

  AssignmentInline:new(
    "assignment inline",
    {is_push_const, is_assignment}),

  IfCondInline:new(
    "if cond inline",
    {is_push_const, is_if}),

}
