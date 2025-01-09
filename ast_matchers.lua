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

local function is_init_local(ast)
  return is(ast, "init_local") and is_stack_consume(ast.val)
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
  return is_push_unop(ast) and is_stack_consume(ast.item.p1)
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
  return is(ast, "if") and is_stack_consume(ast.cond)
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
IfCondInline = AstMatcher:new()
AssignmentInline = AstMatcher:new()
UnaryInline = AstMatcher:new()
DupUnaryInline = AstMatcher:new()
OverUnaryInline = AstMatcher:new()
DupBinaryInline = AstMatcher:new()
OverBinaryInline = AstMatcher:new()
DupDupBinaryInline = AstMatcher:new()
DupIfInline = AstMatcher:new()
OverIfInline = AstMatcher:new()
BinaryInline = AstMatcher:new()
BinaryInlineP2 = AstMatcher:new()
InlineInitLocalConst = AstMatcher:new()

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
 Inline IF conditional

  1.) false not IF ... THEN   =>   IF not false THEN ... END
  2.) 10 v  <   IF ... THEN   =>   IF 10 < v    THEN ... END
  3.)    v      IF ... THEN   =>   IF v         THEN ... END
]]--
function IfCondInline:optimize(ast, i, result)
  self:log("inlining if condition")
  local cond, _if = ast[i], ast[i + 1]
  _if.cond = cond.item
  table.insert(result, _if)
end

--[[
 Inline assignment operator's value operand

  1.) 123 -> v   =>   v = 123
]]--
function AssignmentInline:optimize(ast, i, result)
  self:log("inlining assignment operator's param")
  local p1, op = ast[i], ast[i + 1]
  op.exp = p1.item
  table.insert(result, op)
end

--[[
 Inline unary operator's constant param

  1.) false not   =>   PUSH(not false)
]]--
function UnaryInline:optimize(ast, i, result)
  self:log("inlining unary operator's param")
  local p1, op = ast[i], ast[i + 1]
  op.item.p1 = p1.item
  table.insert(result, op)
end

--[[
 Inline DUP followed by unary operator

  1.) [ 1 2 3 ] DUP size   =>   PUSH(#TOS)
]]--
function DupUnaryInline:optimize(ast, i, result)
  self:log("inlining dup before unary operator")
  local p1, op = ast[i], ast[i + 1]
  op.item.p1.op = "tos"
  op.item.p1.name = "stack_op" -- replace stack_consume to stack_os, to prevent further inlining
  table.insert(result, op)
end

--[[
 Inline OVER followed by unary operator

  1.) true false over not => PUSH(NOT TOS2)
]]--
function OverUnaryInline:optimize(ast, i, result)
  self:log("inlining over before unary operator")
  local p1, op = ast[i], ast[i + 1]
  op.item.p1.op = "tos2"
  op.item.p1.name = "stack_op" -- replace stack_consume to stack_os, to prevent further inlining
  table.insert(result, op)
end

--[[
 Inline DUP followed by binary operator

  1.) 3 DUP *   =>   PUSH(TOS * POP)
]]--
function DupBinaryInline:optimize(ast, i, result)
  self:log("inlining dup before binary operator")
  local p1, p2, op = ast[i], ast[i + 1], ast[i + 2]
  op.item.p1.op = "tos"
  op.item.p1.name = "stack_op" -- replace stack_consume to stack_os, to prevent further inlining
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
    op.item.p1.name = "stack_op"
    op.item.p2.op = "tos"
    op.item.p2.name = "stack_op"
  --else -- results the same
  --  op.item.p1.op = "tos2"
  --  op.item.p1.name = "stack_op"
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
  op.item.p1.name = "stack_op" -- replace stack_consume to stack_os, to prevent further inlining
  op.item.p2.name = "stack_op" -- replace stack_consume to stack_os, to prevent further inlining
  table.insert(result, op)
end

--[[
 Inline DUP followed by IF

  1.) DUP IF .. THEN   =>   TOS IF .. THEN
]]--
function DupIfInline:optimize(ast, i, result)
  self:log("inlining dup before if")
  local dup, _if = ast[i], ast[i + 1]
  _if.cond.op = "tos"
  _if.cond.name = "stack_op" -- replace stack_consume to stack_os, to prevent further inlining
  table.insert(result, _if)
end

--[[
 Inline OVER followed by IF

  1.) OVER IF .. THEN   =>   TOS2 IF .. THEN
]]--
function OverIfInline:optimize(ast, i, result)
  self:log("inlining over before if")
  local over, _if = ast[i], ast[i + 1]
  _if.cond.op = "tos2"
  _if.cond.name = "stack_op" -- replace stack_consume to stack_os, to prevent further inlining
  table.insert(result, _if)
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
    end
  end
  op.item.p2 = p2.item -- inline const param
  if not is_stack_op("dup")(p1) then -- dup was inlined skip it
    table.insert(result, p1)
  end
  table.insert(result, op)
end

--[[
  Used internally
]]--
function InlineInitLocalConst:optimize(ast, i, result)
  self:log("inlining init local constant")
  local p1, init_local = ast[i], ast[i + 1]
  init_local.val = p1.item
  table.insert(result, init_local)
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

  UnaryInline:new(
    "unary inline",
    {is_push_const, is_push_unop_pop}),

  DupUnaryInline:new(
    "dup unary inline",
    {is_stack_op("dup"), is_push_unop_pop}),

  OverUnaryInline:new(
    "over unary inline",
    {is_stack_op("over"), is_push_unop_pop}),

  DupDupBinaryInline:new(
    "dup dup binary inline",
    {is_stack_op("dup"), is_stack_op("dup"), is_push_binop_pop}),

  DupBinaryInline:new(
    "dup binary inline",
    {NOT(is_stack_op("dup")), is_stack_op("dup"), is_push_binop_pop}),

  OverBinaryInline:new(
    "over binary inline",
    {is_stack_op("over"), is_push_binop_pop}),

  DupIfInline:new(
    "dup if inline",
    {is_stack_op("dup"), is_if}),

  OverIfInline:new(
    "over if inline",
    {is_stack_op("over"), is_if}),

  AssignmentInline:new(
    "assignment inline",
    {is_push_const, is_assignment}),

  IfCondInline:new(
    "if cond inline",
    {OR(is_push_const,
        is_push_unop,
        is_push_binop), is_if}), -- TODO 10 3 over < if

  InlineInitLocalConst:new(
    "inline init local const", -- only optimizes one parameter
    {is_push_const, is_init_local}),

}
