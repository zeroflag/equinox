local AstMatcher = {}

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

local function AND(...)
  local fs = {...}
  return function(ast)
    local result = nil
    for i, f in ipairs(fs) do
      if result == nil then
        result = f(ast)
      else
        result = result and f(ast)
      end
    end
    return result
  end
end

local function NOT(f)
  return function(ast)
    return not f(ast)
  end
end

local function is(ast, name) return ast.name == name end
local function any(ast) return ast ~= nil end

local function has(name, matcher)
  return function (ast)
    return matcher(ast[name])
  end
end

local function eq(expected)
  return function (val)
    return val == expected
  end
end

local function has_name(name) return has("name", eq(name)) end
local function has_op(name) return has("op", eq(name)) end
local function has_exp(matcher) return has("exp", matcher) end
local function has_tbl(matcher) return has("tbl", matcher) end
local function has_key(matcher) return has("key", matcher) end
local function has_p1(matcher) return has("p1", matcher) end
local function has_p2(matcher) return has("p2", matcher) end

local is_identifier = has_name("identifier")
local is_literal = has_name("literal")
local is_stack_consume = has_name("stack_consume")
local is_assignment = AND(has_name("assignment"), has_exp(is_stack_consume))
local is_if = AND(has_name("if"), has_exp(is_stack_consume))
local is_init_local = AND(has_name("init_local"), has_exp(is_stack_consume))
local is_push_binop = AND(has_name("push"), has_exp(has_name("bin_op")))
local is_push_unop  = AND(has_name("push"), has_exp(has_name("unary_op")))

local is_literal_tbl_at = AND(
  has_name("table_at"),
  AND(
    OR(has_tbl(is_identifier), has_tbl(is_literal)),
    OR(has_key(is_identifier), has_key(is_literal))))

local is_const = OR(is_identifier, is_literal, is_literal_tbl_at)
local is_push_const = AND(has_name("push"), has_exp(is_const))
local is_push_unop_pop = AND(is_push_unop, has_exp(has_exp(is_stack_consume)))
local is_dup  = AND(has_name("stack_op"), has_op("dup"))
local is_2dup = AND(has_name("stack_op"), has_op("dup2"))
local is_over = AND(has_name("stack_op"), has_op("over"))
local has_p1_pop = has_p1(has_op("pop"))
local has_p2_pop = has_p2(has_op("pop"))

local is_push_binop_pop = AND(
  has_name("push"),
  has_exp(AND(
             has_name("bin_op"),
             has_p1(is_stack_consume),
             has_p2(is_stack_consume))))

local is_wrapped_binop_free_operand = AND(
  has("exp", any),
  has_exp(AND(
             has_name("bin_op"),
             OR(has_p1_pop,
                has_p2_pop))))

local inlined_push_unop = AND(
  is_push_unop,
  NOT(has_exp(has_exp(is_stack_consume))))

local inlined_push_binop = AND(
  is_push_binop,
  OR(
    -- fully inlined
    AND(NOT(has_exp(has_p1(is_stack_consume)), NOT(has_exp(has_p2(is_stack_consume))))),
    -- partially inlined
    AND(has_exp(has_p1_pop), NOT(has_exp(has_p2(is_stack_consume)))),
    AND(has_exp(has_p2_pop), NOT(has_exp(has_p1(is_stack_consume))))))

local is_tbl_at = AND(
  has_name("push"),
  has_exp(
    AND(
      has_name("table_at"),
      has_tbl(is_stack_consume),
      has_key(is_stack_consume))))

local is_tbl_put = AND(
  has_name("table_put"),
  has_tbl(is_stack_consume),
  has_key(is_stack_consume))

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
  op.exp.tbl = tbl.exp
  op.exp.key = idx.exp
  table.insert(result, op)
end

--[[
 Inline table at index parameter
  1.)  ... 4 at   =>   PUSH(POP[4])
]]--
function AtParamsInlineP2:optimize(ast, i, result)
  self:log("inlining tbl at 2nd param")
  local tbl, idx, op = ast[i], ast[i + 1], ast[i + 2]
  if op.exp.tbl.name == "stack_consume" and
     op.exp.tbl.op == "pop2nd"
  then
    op.exp.tbl.op = "pop"
  end
  op.exp.key = idx.exp
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
  op.tbl = tbl.exp
  op.key = key.exp
  op.value = val.exp
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
    target = operator.exp
  else
    target = operator
  end

  if is_dup(p1) then
    self:log(operator.name .. " (dup)")
    target.exp.op = "tos"
    target.exp.name ="stack_peek"
  elseif is_over(p1) then
    self:log(operator.name .. " (over)")
    target.exp.op = "tos2"
    target.exp.name ="stack_peek"
  else
    self:log(operator.name)
    target.exp = p1.exp
  end

  table.insert(result, operator)
end

function InlineGeneralUnary:optimize(ast, i, result)
  local p1, operator = ast[i], ast[i + 1]
  local target
  if is_push_unop_pop(operator) then
    -- unary is embedded into a push
    target = operator.exp
  else
    target = operator
  end

  if is_dup(p1) then
    self:log(operator.name .. " (dup)")
    target.exp.op = "tos"
    target.exp.name ="stack_peek"
  elseif is_over(p1) then
    self:log(operator.name .. " (over)")
    target.exp.op = "tos2"
    target.exp.name ="stack_peek"
  else
    self:log(operator.name)
    target.exp = p1.exp
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
  if is_dup(p1) and is_dup(p2) then
    -- double dup
    self:log("dup dup")
    op.exp.p1.op = "tos"
    op.exp.p2.op = "tos"
    op.exp.p1.name = "stack_peek"
    op.exp.p2.name = "stack_peek"
    table.insert(result, op)
  elseif is_2dup(p2) then
    self:log("2dup")
    op.exp.p1.op = "tos2"
    op.exp.p2.op = "tos"
    op.exp.p1.name = "stack_peek"
    op.exp.p2.name = "stack_peek"
    table.insert(result, p1)
    table.insert(result, op)
  elseif is_dup(p2) then
    -- single dup
    self:log("single dup")
    op.exp.p1.op = "tos"
    op.exp.p1.name = "stack_peek"
    table.insert(result, p1)
    table.insert(result, op)
  elseif is_over(p2) then
    -- single over
    self:log("over")
    op.exp.p1.op = "pop"
    op.exp.p1.name = "stack_peek"
    op.exp.p2.op = "tos"
    op.exp.p2.name = "stack_peek"
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
  op.exp.p1 = p1.exp
  op.exp.p2 = p2.exp
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
  if op.exp.p1.name == "stack_consume" then
    if op.exp.p1.op == "pop2nd" then
      op.exp.p1.op = "pop"
    end
    if is_dup(p1) then
      op.exp.p1.op = "tos" -- inline if dup
      op.exp.p1.name = "stack_peek"
    end
  end
  op.exp.p2 = p2.exp -- inline const param
  if not is_dup(p1) then -- dup was inlined skip it
    table.insert(result, p1)
  end
  table.insert(result, op)
end

function BinaryConstBinaryInline:optimize(ast, i, result)
  self:log("inlining binary to binary operator")
  local bin, op = ast[i], ast[i + 1]
  local target = op.exp
  if target.p1.op == "pop" then
    target.p1 = bin.exp
    if target.p2.op == "tos" then
      target.p2 = bin.exp
    elseif target.p2.op == "pop2nd" then
      target.p2.op = "pop"
    end
  elseif target.p2.op == "pop" then
    target.p2 = bin.exp
    if target.p1.op == "tos" then
      target.p1 = bin.exp
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
     {OR(inlined_push_binop,
         inlined_push_unop),
      is_wrapped_binop_free_operand}),

  StackOpBinaryInline:new(
    "stackop binary inline",
    {any, OR(is_dup,
             is_2dup,
             is_over), is_push_binop_pop}),

  InlineGeneralUnary:new(
    "inline general unary",
    {OR(is_dup,
        is_over,
        is_push_const,
        is_push_unop,
        is_push_binop),
     OR(is_init_local,  -- init-local only optimizes one parameter
        is_assignment,
        is_if,
        is_push_unop_pop)}),
}
