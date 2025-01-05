local AstMatcher = {}

function is(ast, name) return ast.name == name end
function is_literal(ast) return is(ast, "literal") end
function is_identifier(ast) return is(ast, "identifier") end

function is_const(ast)
  return is_identifier(ast)
    or is_literal(ast)
    or is_tbl_at_with_const_params(ast)
end

function is_push_const(ast)
  return is(ast, "push") and is_const(ast.item)
end

function is_tbl_at_with_const_params(ast)
  return is(ast, "table_at")
    and (is_identifier(ast.tbl) or is_literal(ast.tbl))
    and (is_identifier(ast.key) or is_literal(ast.key))
end

function OR(f1, f2)
  return function(ast)
    return f1(ast) or f2(ast)
  end
end

function AND(f1, f2)
  return function(ast)
    return f1(ast) and f2(ast)
  end
end

function NOT(f)
  return function(ast)
    return not f(ast)
  end
end
function AND(f1, f2)
  return function(ast)
    return f1(ast) and f2(ast)
  end
end

function is_stack_op(op)
  return function(ast)
    return is(ast, "stack_op") and ast.op == op
  end
end

function is_push_binop(ast)
  return is(ast, "push")
    and is(ast.item, "bin_op")
    and is(ast.item.p1, "stack_access")
    and is(ast.item.p2, "stack_access")
end

function is_push_inlined_binop(ast)
  return is(ast, "push")
    and is(ast.item, "bin_op")
    and is_const(ast.item.p1)
    and is_const(ast.item.p2)
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
  local obj = {name = name, parts = parts, logging = false}
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
  if self.logging then
    print("[OPTI] " .. message)
  end
end

function AstMatcher:size()
  return #self.parts
end

AtParamsInline = AstMatcher:new()
AtParamsInlineP2 = AstMatcher:new()
PutParamsInline = AstMatcher:new()
IfCondInline = AstMatcher:new()
AssignmentInline = AstMatcher:new()
UnaryInline = AstMatcher:new()
DupUnaryInline = AstMatcher:new()
DupIfInline = AstMatcher:new()
BinaryInline = AstMatcher:new()
BinaryInlineP2 = AstMatcher:new()

function AtParamsInline:optimize(ast, i, result)
  self:log("inlining tbl at params")
  local tbl, idx, op = ast[i], ast[i + 1], ast[i + 2]
  op.item.tbl = tbl.item
  op.item.key = idx.item
  table.insert(result, op)
end

function AtParamsInlineP2:optimize(ast, i, result)
  self:log("inlining tbl at 2nd param")
  local tbl, idx, op = ast[i], ast[i + 1], ast[i + 2]
  if op.item.tbl.name == "stack_access" and
     op.item.tbl.op == "pop2nd" then
    op.item.tbl.op = "pop"
  end
  op.item.key = idx.item
  table.insert(result, tbl)
  table.insert(result, op)
end

function PutParamsInline:optimize(ast, i, result)
  self:log("inlining tbl put params")
  local tbl, key, val, op = ast[i], ast[i + 1], ast[i + 2], ast[i + 3]
  op.tbl = tbl.item
  op.key = key.item
  op.value = val.item
  table.insert(result, op)
end

function IfCondInline:optimize(ast, i, result)
  self:log("inlining if condition")
  local cond, _if = ast[i], ast[i + 1]
  _if.cond = cond.item
  table.insert(result, _if)
end

function AssignmentInline:optimize(ast, i, result)
  self:log("inlining assignment operator's param")
  local p1, op = ast[i], ast[i + 1]
  op.exp = p1.item
  table.insert(result, op)
end

function UnaryInline:optimize(ast, i, result)
  self:log("inlining unary operator's param")
  local p1, op = ast[i], ast[i + 1]
  op.item.p1 = p1.item
  table.insert(result, op)
end

function DupUnaryInline:optimize(ast, i, result)
  self:log("inlining dup before unary operator")
  local p1, op = ast[i], ast[i + 1]
  op.item.p1.op = "tos"
  op.item.p1.name = "stack_op" -- replace stack_access to stack_os, to prevent further inlining
  table.insert(result, op)
end

function DupIfInline:optimize(ast, i, result)
  self:log("inlining dup before if")
  local dup, _if = ast[i], ast[i + 1]
  _if.cond.op = "tos"
  _if.cond.name = "stack_op" -- replace stack_access to stack_os, to prevent further inlining
  table.insert(result, _if)
end

function BinaryInline:optimize(ast, i, result)
  self:log("inlining binary operator params")
  local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
  op.item.p1 = p1.item
  op.item.p2 = p2.item
  table.insert(result, op)
end

function BinaryInlineP2:optimize(ast, i, result)
  self:log("inlining binary operator's 2nd param")
  local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
  if op.item.p1.name == "stack_access" and
     op.item.p1.op == "pop2nd" then
    op.item.p1.op = "pop"
  end
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

  AtParamsInlineP2:new(
    "inline at p2",
    {NOT(is_push_const), is_push_const, is_tbl_at}),

  BinaryInline:new(
    "binary inline",
    {is_push_const, is_push_const, is_push_binop}),

  BinaryInlineP2:new(
    "binary p2 inline",
    {NOT(is_push_const), is_push_const, is_push_binop}),

  UnaryInline:new(
    "unary inline",
    {is_push_const, is_push_unop}),

  DupUnaryInline:new(
    "dup unary inline",
    {is_stack_op("dup"), is_push_unop}),

  DupIfInline:new(
    "dup unary inline",
    {is_stack_op("dup"), is_if}),

  AssignmentInline:new(
    "assignment inline",
    {is_push_const, is_assignment}),

  -- TODO inlined unop
  IfCondInline:new(
    "if cond inline",
    {OR(is_push_const,
        is_push_inlined_binop), is_if}),
}
