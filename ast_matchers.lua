local AstMatcher = {}

local function is(ast, name) return ast.name == name end
local function is_literal(ast) return is(ast, "literal") end
local function is_identifier(ast) return is(ast, "identifier") end
local function is_stack_consume(ast) return is(ast, "stack_consume") end

local function is_literal_tbl_at(ast)
  return is(ast, "table_at")
    and (is_identifier(ast.tbl) or is_literal(ast.tbl))
    and (is_identifier(ast.key) or is_literal(ast.key))
end

local function is_const(ast)
  return is_identifier(ast)
    or is_literal(ast)
    or is_literal_tbl_at(ast)
end

local function is_push_const(ast)
  return is(ast, "push") and is_const(ast.item)
end

local function OR(...)
  local fs = {...}
  return function(ast)
    local result = false
    for i, f in ipairs(fs) do
      result = result or f(ast)
    end
    return result
  end
end

local function NOT(f)
  return function(ast)
    return not f(ast)
  end
end

local function is_stack_op(op)
  return function(ast)
    return is(ast, "stack_op") and ast.op == op
  end
end

local function is_push_binop(ast)
  return is(ast, "push") and is(ast.item, "bin_op")
end

local function is_push_binop_pop(ast)
  return is_push_binop(ast)
    and is_stack_consume(ast.item.p1)
    and is_stack_consume(ast.item.p2)
end

local function is_push_unop(ast)
  return is(ast, "push") and is(ast.item, "unary_op")
end

local function is_push_unop_pop(ast)
  return is_push_unop(ast) and is_stack_consume(ast.item.exp)
end

local function is_tbl_at(ast)
  return is(ast, "push")
    and is(ast.item, "table_at")
    and is_stack_consume(ast.item.tbl)
    and is_stack_consume(ast.item.key)
end

local function is_tbl_put(ast)
  return is(ast, "table_put") -- no push here
    and is_stack_consume(ast.tbl)
    and is_stack_consume(ast.key)
end

local function is_assignment(ast)
  return is(ast, "assignment") and is_stack_consume(ast.exp)
end

local function is_if(ast)
  return is(ast, "if") and is_stack_consume(ast.exp)
end

local function is_init_local(ast)
  return is(ast, "init_local") and is_stack_consume(ast.exp)
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
    print("[OPTI] " .. self.name .. ": " .. message)
  end
end

function AstMatcher:size()
  return #self.parts
end

AtParamsInline = AstMatcher:new()
AtParamsInlineP2 = AstMatcher:new()
PutParamsInline = AstMatcher:new()
DupBinaryInline = AstMatcher:new()
OverBinaryInline = AstMatcher:new()
DupDupBinaryInline = AstMatcher:new()
BinaryInline = AstMatcher:new()
BinaryInlineP2 = AstMatcher:new()
InlineGeneralUnary = AstMatcher:new()

--[[
 Inline table at parameters
  1.)  t  4 at   =>   PUSH(t[4])
]]--
function AtParamsInline:optimize(ast, i, result)
  self:log("inlining tbl at params")
  local tbl, idx, op = ast[i], ast[i + 1], ast[i + 2]
  op.item.tbl = tbl.item
  op.item.key = idx.item
  table.insert(result, op)
end

--[[
 Inline table at index parameter
  1.)  ... 4 at   =>   PUSH(POP[4])
]]--
function AtParamsInlineP2:optimize(ast, i, result)
  self:log("inlining tbl at 2nd param")
  local tbl, idx, op = ast[i], ast[i + 1], ast[i + 2]
  if op.item.tbl.name == "stack_consume" and
     op.item.tbl.op == "pop2nd"
  then
    op.item.tbl.op = "pop"
  end
  op.item.key = idx.item
  table.insert(result, tbl)
  table.insert(result, op)
end

--[[
 Inline table put parameters
  1.)  t 4 "abc" put   =>   t[4]="abc"
]]--
function PutParamsInline:optimize(ast, i, result)
  self:log("inlining tbl put params")
  local tbl, key, val, op = ast[i], ast[i + 1], ast[i + 2], ast[i + 3]
  op.tbl = tbl.item
  op.key = key.item
  op.value = val.item
  table.insert(result, op)
end

--[[
 Inline assignment/init-local(used internal) operator's value operand

  1.) 123 -> v   =>   v = 123
  2.) false not   =>   PUSH(not false)
  3.) false not IF ... THEN   =>   IF not false THEN ... END
  4.) 10 v  <   IF ... THEN   =>   IF 10 < v    THEN ... END
  5.)    v      IF ... THEN   =>   IF v         THEN ... END
  6.) DUP IF .. THEN   =>   TOS IF .. THEN
  7.) OVER IF .. THEN   =>   TOS2 IF .. THEN
  8.) [ 1 2 3 ] DUP size   =>   PUSH(#TOS)
  9.) true false over not => PUSH(NOT TOS2)
]]--
function InlineGeneralUnary:optimize(ast, i, result)
  local p1, operator = ast[i], ast[i + 1]
  local target
  if is_push_unop_pop(operator) then
    -- unary is embedded into a push
    target = operator.item
  else
    target = operator
  end

  if is_stack_op("dup")(p1) then
    self:log(operator.name .. " (dup)")
    target.exp.op = "tos"
    target.exp.name ="stack_peek"
  elseif is_stack_op("over")(p1) then
    self:log(operator.name .. " (over)")
    target.exp.op = "tos2"
    target.exp.name ="stack_peek"
  else
    self:log(operator.name)
    target.exp = p1.item
  end

  table.insert(result, operator)
end

--[[
 Inline DUP followed by binary operator

  1.) 3 DUP *   =>   PUSH(TOS * POP)
]]--
function DupBinaryInline:optimize(ast, i, result)
  self:log("inlining dup before binary operator")
  local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
  op.item.p1.op = "tos"
  op.item.p1.name = "stack_peek"
  table.insert(result, p1)
  table.insert(result, op)
end

--[[
 Inline OVER followed by binary operator

  1.) 3 7 OVER +   =>   PUSH(TOS2 + POP)
  2.) 3 7 OVER -   =>   PUSH(POP  - TOS)
]]--
function OverBinaryInline:optimize(ast, i, result)
  self:log("inlining over before binary operator")
  local over, op = ast[i], ast[i + 1]
  --if op.item.p1.op == "pop2nd" then
    op.item.p1.op = "pop"
    op.item.p1.name = "stack_peek"
    op.item.p2.op = "tos"
    op.item.p2.name = "stack_peek"
  --else -- results the same
  --  op.item.p1.op = "tos2"
  --  op.item.p1.name = "stack_peek"
  --end
  table.insert(result, op)
end

--[[
 Inline DUPs followed by binary operator

  1.) DUP DUP *   =>   PUSH(TOS * TOS)
]]--
function DupDupBinaryInline:optimize(ast, i, result)
  self:log("inlining dup dup before binary operator")
  local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
  op.item.p1.op = "tos"
  op.item.p2.op = "tos"
  op.item.p1.name = "stack_peek"
  op.item.p2.name = "stack_peek"
  table.insert(result, op)
end

--[[
 Inline binary operator's ALL constant operands

  1.) 12      45 +   =>   PUSH(12   + 45)
  2.) 12      v1 +   =>   PUSH(12   + v1)
  3.) t 1 at  45 +   =>   PUSH(t[1] + 45)
]]--
function BinaryInline:optimize(ast, i, result)
  self:log("inlining binary operator params")
  local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
  op.item.p1 = p1.item
  op.item.p2 = p2.item
  table.insert(result, op)
end

--[[
 Inline binary operator's 2nd, constant operand
 Additonally replace DUP with DROP if applicable

  1.)      123 +   =>   PUSH(POP + 123)
  2.)  DUP 123 +   =>   PUSH(TOS + 123)
]]--
function BinaryInlineP2:optimize(ast, i, result)
  self:log("inlining binary operator's 2nd param")
  local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
  if op.item.p1.name == "stack_consume" then
    if op.item.p1.op == "pop2nd" then
      op.item.p1.op = "pop"
    end
    if is_stack_op("dup")(p1) then
      op.item.p1.op = "tos" -- inline if dup
      op.item.p1.name = "stack_peek"
    end
  end
  op.item.p2 = p2.item -- inline const param
  if not is_stack_op("dup")(p1) then -- dup was inlined skip it
    table.insert(result, p1)
  end
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
    {is_push_const, is_push_const, is_push_binop_pop}),

  BinaryInlineP2:new(
    "binary p2 inline",
    {NOT(is_push_const), is_push_const, is_push_binop_pop}),

  DupDupBinaryInline:new(
    "dup dup binary inline",
    {is_stack_op("dup"), is_stack_op("dup"), is_push_binop_pop}),

  DupBinaryInline:new(
    "dup binary inline",
    {NOT(is_stack_op("dup")), is_stack_op("dup"), is_push_binop_pop}),

  OverBinaryInline:new(
    "over binary inline",
    {is_stack_op("over"), is_push_binop_pop}),

  InlineGeneralUnary:new(
    "inline general unary",
    {OR(is_stack_op("dup"),
        is_stack_op("over"),
        is_push_const,
        is_push_unop,
        is_push_binop),
     OR(is_init_local,  -- init-local only optimizes one parameter
        is_assignment,
        is_if,
        is_push_unop_pop)}),

}
