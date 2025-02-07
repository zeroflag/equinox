local AstMatcher = {}

local function is(ast, name) return ast.name == name end
local function is_literal(ast) return is(ast, "literal") end
local function is_identifier(ast) return is(ast, "identifier") end
local function any(ast) return ast ~= nil end
local function is_binop(ast) return is(ast, "bin_op") end
local function is_unop(ast) return is(ast, "unary_op") end

local function is_push(ast, item_pred)
  if not is(ast, "push") then
    return false
  end
  if item_pred == nil then
    return true
  end
  return item_pred(ast.item)
end

local function is_stack_consume(ast, op_name)
  if is(ast, "stack_consume") then
    return op_name == nil or ast.op == op_name
  end
  return false
end

local function is_stack_peek(ast, op_name)
  if is(ast, "stack_peek") then
    return op_name == nil or ast.op == op_name
  end
  return false
end

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
  return is_push(ast, is_const)
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
  return is_push(ast, is_binop)
end

local function is_push_unop(ast)
  return is_push(ast, is_unop)
end

local function is_push_binop_pop(ast)
  return is_push_binop(ast)
    and is_stack_consume(ast.item.p1)
    and is_stack_consume(ast.item.p2)
end

local function is_push_non_destructive_op(ast)
  return
    (is_push_binop(ast)
     and
     ((not is_stack_consume(ast.item.p1) and
      not is_stack_consume(ast.item.p2))
     or
     (is_stack_consume(ast.item.p1, "pop") and
      not is_stack_consume(ast.item.p2))
     or
     (is_stack_consume(ast.item.p2, "pop") and
      not is_stack_consume(ast.item.p1))))
    or (is_push_unop(ast) and not is_stack_consume(ast.item.exp))
end

local function is_push_binop_pop_p1_or_p2(ast)
  return is_push_binop(ast) and
    (is_stack_consume(ast.item.p1, "pop") or
     is_stack_consume(ast.item.p2, "pop"))
end

local function is_if_binop_p1_or_p2(ast)
  return is(ast, 'if') and is_binop(ast.exp) and
    (is_stack_consume(ast.exp.p1, "pop") or
     is_stack_consume(ast.exp.p2, "pop"))
end

local function is_push_unop_pop(ast)
  return is_push_unop(ast) and is_stack_consume(ast.item.exp)
end

local function is_tbl_at(ast)
  return is_push(ast)
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
StackOpBinaryInline = AstMatcher:new()
BinaryInline = AstMatcher:new()
BinaryInlineP2 = AstMatcher:new()
BinaryConstBinaryInline = AstMatcher:new()
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

  1.) 3 DUP *      =>   PUSH(TOS * POP)
  2.) DUP DUP *    =>   PUSH(TOS * TOS)
  3.) 3 7 OVER +   =>   PUSH(TOS2 + POP)
  4.) 3 7 OVER -   =>   PUSH(POP  - TOS)
  5.) 1 2 2DUP +   =>   PUSH(TOS + TOS)
]]--
function StackOpBinaryInline:optimize(ast, i, result)
  local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
  if is_stack_op("dup")(p1) and is_stack_op("dup")(p2) then
    -- double dup
    self:log("dup dup")
    op.item.p1.op = "tos"
    op.item.p2.op = "tos"
    op.item.p1.name = "stack_peek"
    op.item.p2.name = "stack_peek"
    table.insert(result, op)
  elseif is_stack_op("dup2")(p2) then
    self:log("2dup")
    op.item.p1.op = "tos2"
    op.item.p2.op = "tos"
    op.item.p1.name = "stack_peek"
    op.item.p2.name = "stack_peek"
    table.insert(result, p1)
    table.insert(result, op)
  elseif is_stack_op("dup")(p2) then
    -- single dup
    self:log("single dup")
    op.item.p1.op = "tos"
    op.item.p1.name = "stack_peek"
    table.insert(result, p1)
    table.insert(result, op)
  elseif is_stack_op("over")(p2) then
    -- single over
    self:log("over")
    op.item.p1.op = "pop"
    op.item.p1.name = "stack_peek"
    op.item.p2.op = "tos"
    op.item.p2.name = "stack_peek"
    table.insert(result, p1)
    table.insert(result, op)
  else
    error("Unexpected p2: " .. tostring(p2.name))
  end
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

function BinaryConstBinaryInline:optimize(ast, i, result)
  self:log("inlining binary to binary operator")
  local bin, op = ast[i], ast[i + 1]
  local target = op
  if is(op, "if") then
    target = op.exp
  else
    target = op.item
  end
  if target.p1.op == "pop" then
    target.p1 = bin.item
    if target.p2.op == "tos" then
      target.p2 = bin.item
    elseif target.p2.op == "pop2nd" then
      target.p2.op = "pop"
    end
  elseif target.p2.op == "pop" then
    target.p2 = bin.item
    if target.p1.op == "tos" then
      target.p1 = bin.item
    elseif target.p1.op == "pop2nd" then
      target.p1.op = "pop"
    end
  else -- shouldn't happen
    error("one of binary operator's param was expected to be stack_consime")
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

  BinaryConstBinaryInline:new(
    "binary const binary inline",
     {is_push_non_destructive_op,
      OR(is_push_binop_pop_p1_or_p2, is_if_binop_p1_or_p2)}),

  StackOpBinaryInline:new(
    "stackop binary inline",
    {any, OR(is_stack_op("dup"),
             is_stack_op("dup2"), -- 2dup
             is_stack_op("over")), is_push_binop_pop}),

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
