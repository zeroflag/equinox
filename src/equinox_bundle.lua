do
local _ENV = _ENV
package.preload[ "ast" ] = function( ... ) local arg = _G.arg;
local ast = {}

local id_counter = 1

function ast.gen_id(prefix)
  id_counter = id_counter + 1
  return prefix .. id_counter
end

function ast.func_header(func_name, global)
  return {
    name = "func_header",
    func_name = func_name,
    params = {},
    global = global
  }
end

function ast.end_func(func_name)
  return {name = "end_func", func_name = func_name}
end

function ast.func_call(func_name, ...)
  return {
    name = "func_call",
    func_name = func_name,
    args = {...}
  }
end

function ast.pop()
  return {name = "stack_consume", op  = "pop"}
end

function ast.pop2nd()
  return {name = "stack_consume", op  = "pop2nd"}
end

function ast.pop3rd()
  return {name = "stack_consume", op  = "pop3rd"}
end

function ast.stack_op(operation)
  return {name = "stack_op", op = operation}
end

function ast.aux_op(operation)
  return {name = "aux_op", op = operation}
end

function ast.push(exp)
  return {name  = "push", exp = exp}
end

function ast.push_many(func_call)
  return {name  = "push_many", func_call = func_call}
end

function ast.aux_push(exp)
  return {name  = "push_aux", exp = exp}
end

function ast._while(cond)
  return {
    name = "while",
    cond = cond
  }
end

function ast._until(cond)
  return {
    name = "until",
    cond = cond
  }
end

function ast.literal(kind, value)
  return {
    name = "literal",
    kind = kind,
    value = value
  }
end

function ast.str(val)
  return ast.literal("string", val)
end

function ast.bin_op(operator, param1, param2)
  return {
    name = "bin_op",
    op = operator,
    p1 = param1,
    p2 = param2
  }
end

function ast.unary_op(operator, operand)
  return {name = "unary_op", op = operator, exp = operand}
end

function ast.assignment(var, exp)
  return {name = "assignment", var  = var, exp  = exp}
end

function ast.init_local(var, exp)
  return {name = "init_local", var = var, exp = exp}
end

function ast.init_global(var, exp)
  return {name = "init_global", var = var, exp = exp}
end

function ast._if(cond, body)
  return {name = "if", exp = cond, body = body}
end

function ast.def_local(var)
  return {name = "local", var = var}
end

function ast.def_global(var)
  return {name = "global", var = var}
end

function ast.new_table()
  return {name = "table_new"}
end

function ast.table_at(tbl, key)
  return {name = "table_at", key = key, tbl = tbl}
end

function ast.table_put(tbl, key, value)
  return {
    name = "table_put",
    tbl = tbl,
    key = key,
    value = value
  }
end

function ast.keyword(keyword)
  return {name = "keyword", keyword = keyword}
end

function ast.identifier(id)
  return {name = "identifier", id = id}
end

function ast._return(opt_arg)
  return {name = "return", arg = opt_arg}
end

function ast._for(loop_var, start, stop, step)
  return {
    name = "for",
    loop_var = loop_var,
    start = start,
    stop = stop,
    step = step
  }
end

function ast._foreach(loop_var1, loop_var2, iterable)
  return {
    name = "for_each",
    loop_var1 = loop_var1,
    loop_var2 = loop_var2,
    iterable = iterable
  }
end

function ast._ipairs(iterable)
  return {name = "ipairs", iterable = iterable}
end

function ast._pairs(iterable)
  return {name = "pairs", iterable = iterable}
end

return ast
end
end

do
local _ENV = _ENV
package.preload[ "ast_matchers" ] = function( ... ) local arg = _G.arg;
local asts = require("ast")

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
local function has_value(val) return has("value", eq(val)) end

local is_identifier = has_name("identifier")
local is_literal = has_name("literal")
local is_stack_consume = has_name("stack_consume")
local is_assignment = AND(has_name("assignment"), has_exp(is_stack_consume))
local is_if = AND(has_name("if"), has_exp(is_stack_consume))
local is_init_local = AND(has_name("init_local"), has_exp(is_stack_consume))
local is_push_binop = AND(has_name("push"), has_exp(has_name("bin_op")))
local is_push_unop  = AND(has_name("push"), has_exp(has_name("unary_op")))
local is_pop = AND(is_stack_consume, has_op("pop"))

local is_literal_tbl_at = AND(
  has_name("table_at"),
  AND(
    OR(has_tbl(is_identifier), has_tbl(is_literal)),
    OR(has_key(is_identifier), has_key(is_literal))))

local is_const = OR(is_identifier, is_literal, is_literal_tbl_at)
local is_push_const = AND(has_name("push"), has_exp(is_const))
local is_push_unop_pop = AND(is_push_unop, has_exp(has_exp(is_stack_consume)))
local is_stack_op = has_name("stack_op")
local is_stack_peek = has_name("stack_peek")
local is_dup  = AND(is_stack_op, has_op("dup"))
local is_2dup = AND(is_stack_op, has_op("dup2"))
local is_over = AND(is_stack_op, has_op("over"))
local is_tos  = AND(is_stack_peek, has_op("tos"))
local has_p1_pop = has_p1(has_op("pop"))
local has_p2_pop = has_p2(has_op("pop"))
local has_lit_value = AND(is_literal, has("value", eq(1)))

local is_push_binop_pop = AND(
  has_name("push"),
  has_exp(AND(
             has_name("bin_op"),
             has_p1(is_stack_consume),
             has_p2(is_stack_consume))))

local is_exp_binop_pop = AND(
  has("exp", any),
  has_exp(AND(
             has_name("bin_op"),
             has_p1(is_stack_consume),
             has_p2(is_stack_consume))))

local is_wrapped_binop_tos = AND(
  has("exp", any),
  has_exp(AND(
             has_name("bin_op"),
             OR(
               AND(has_p1(is_tos)),
               AND(has_p2(is_tos), NOT(has_p1(is_stack_consume)))))))

local is_inc = AND(
  has_name("push"),
  has_exp(AND(
            has_name("bin_op"),
            has_op("+"),
            OR(
              AND(has_p1_pop, has_p2(has_value(1))),
              AND(has_p2_pop, has_p1(has_value(1)))))))

local is_neg = AND(
  has_name("push"),
  has_exp(AND(
            has_name("unary_op"),
            has_exp(is_pop),
            has_op("not"))))

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
TosBinaryInline = AstMatcher:new()
IncInline = AstMatcher:new()
NegInline = AstMatcher:new()

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
  self:log("inlining stack op in binary")
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
    op.exp.p1.name = "stack_consume"
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
    error("one of binary operator's param was expected to be stack_consume")
  end
  table.insert(result, op)
end

function TosBinaryInline:optimize(ast, i, result)
  self:log("inlining binary tos operand")
  local cons, op = ast[i], ast[i + 1]
  if op.exp.p1.op == "tos" then
    op.exp.p1 = cons.exp
  end
  if op.exp.p2.op == "tos" then
    op.exp.p2 = cons.exp
  end
  table.insert(result, cons)
  table.insert(result, op)
end

function IncInline:optimize(ast, i, result)
  self:log("inlining inc")
  table.insert(result, asts.stack_op("_inc"))
end

function NegInline:optimize(ast, i, result)
  self:log("inlining neg")
  table.insert(result, asts.stack_op("_neg"))
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
    {is_push_const, is_push_const, is_exp_binop_pop}),

  BinaryInlineP2:new(
    "binary p2 inline",
    {NOT(is_push_const), is_push_const, is_exp_binop_pop}),

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

  TosBinaryInline:new(
    "tos binary inline",
    {is_push_const, is_wrapped_binop_tos}),

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

  IncInline:new("inline inc", {is_inc}),
  NegInline:new("inline neg", {is_neg}),
}
end
end

do
local _ENV = _ENV
package.preload[ "ast_optimizer" ] = function( ... ) local arg = _G.arg;
local Optimizer = {}
local matchers = require("ast_matchers")

function Optimizer:new()
  local obj = {logging = false, enabled = true}
  setmetatable(obj, {__index = self})
  return obj
end

function Optimizer:enable_logging(bool)
  self.logging = bool
end

function Optimizer:enable(bool)
  self.enabled = bool
end

function Optimizer:log_ast(node)
  --require("tests/json")
  --self:log("AST: " .. to_json_str(node))
end

function Optimizer:log(txt)
  if self.logging then
    print("[OPTI] " .. txt)
  end
end

function Optimizer:optimize_iteratively(ast)
  if not self.enabled then return ast end
  local num_of_optimizations, iterations = 0, 0
  repeat
    ast, num_of_optimizations = self:optimize(ast)
    iterations = iterations + 1
    self:log(string.format(
          "Iteration: %d finished. Number of optimizations: %d",
          iterations, num_of_optimizations))
    if iterations > 100 then
      print("Aborting optimizer. This is likely a bug.")
      break
    end
  until num_of_optimizations == 0
  return ast
end

function Optimizer:optimize(ast)
  local result, i, num_matches = {}, 1, 0
  while i <= #ast do
    local node = ast[i]
    self:log_ast(node)
    local found = false
    for _, matcher in ipairs(matchers) do
      if matcher:matches(ast, i) then
        matcher.logging = self.logging
        matcher:optimize(ast, i, result)
        i = i + matcher:size()
        num_matches = num_matches + 1
        found = true
      end
    end
    if not found then
      table.insert(result, node)
      i = i + 1
    end
  end
  return result, num_matches
end

return Optimizer
end
end

do
local _ENV = _ENV
package.preload[ "codegen" ] = function( ... ) local arg = _G.arg;
local CodeGen = {}

function CodeGen:new()
  local obj = {}
  setmetatable(obj, {__index = self})
  return obj
end

local function lit_bin_op(ast)
  return ast.name == "bin_op"
    and ast.p1.name == "literal"
    and ast.p2.name == "literal"
end

local function lit_unary_op(ast)
  return ast.name == "unary_op" and ast.exp.name == "literal"
end

local function inline_push(exp)
  return "stack[#stack +1] = " .. exp
end

function CodeGen:gen(ast)
  if "stack_op" == ast.name
    or "stack_consume" == ast.name
    or "stack_peek" == ast.name
  then
    return ast.op .. "()"
  end
  if "aux_op" == ast.name then
    return "a" .. ast.op .. "()"
  end
  if "push" == ast.name then
    if ast.exp.name == "literal" or
       lit_bin_op(ast.exp) or
       lit_unary_op(ast.exp)
    then
      return inline_push(self:gen(ast.exp)) -- bypass NIL check
    else
      return string.format("push(%s)", self:gen(ast.exp))
    end
  end
  if "push_many" == ast.name then
    return string.format("push_many(%s)", self:gen(ast.func_call))
  end
  if "push_aux" == ast.name then
    return string.format("apush(%s)", self:gen(ast.exp))
  end
  if "unary_op" == ast.name then
    return string.format("%s %s", ast.op, self:gen(ast.exp))
  end
  if "bin_op" == ast.name then
    return string.format(
      "(%s %s %s)", self:gen(ast.p1), ast.op, self:gen(ast.p2))
  end
  if "local" == ast.name then
    return "local " .. ast.var
  end
  if "global" == ast.name then
    return ast.var .. "=nil"
  end
  if "init_local" == ast.name then
    return "local " .. ast.var .. "=" .. self:gen(ast.exp)
  end
  if "init_global" == ast.name then
    return ast.var .. "=" .. self:gen(ast.exp)
  end
  if "assignment" == ast.name then
    return ast.var .. " = " .. self:gen(ast.exp)
  end
  if "literal" == ast.name and "boolean" == ast.kind then
    return ast.value
  end
  if "literal" == ast.name and "string" == ast.kind then
    return '"' .. ast.value .. '"'
  end
  if "literal" == ast.name and "number" == ast.kind then
    return ast.value
  end
  if "while" == ast.name then
    return string.format("while (%s) do", self:gen(ast.cond))
  end
  if "until" == ast.name then
    return string.format("until %s", self:gen(ast.cond))
  end
  if "for" == ast.name and not ast.step then
      return string.format(
        "for %s=%s,%s do",
        ast.loop_var, self:gen(ast.start), self:gen(ast.stop))
  end
  if "for" == ast.name and ast.step then
      return string.format(
        "for %s=%s,%s,%s do",
        ast.loop_var,
        self:gen(ast.start),
        self:gen(ast.stop),
        self:gen(ast.step))
  end
  if "for_each" == ast.name then
    if ast.loop_var1 and ast.loop_var2 then
      return string.format(
        "for %s,%s in %s do",
        ast.loop_var1, ast.loop_var2, self:gen(ast.iterable))
    else
      return string.format(
        "for %s in %s do",
        ast.loop_var1, self:gen(ast.iterable))
    end
  end
  if "pairs" == ast.name then
    return string.format("pairs(%s)", self:gen(ast.iterable))
  end
  if "ipairs" == ast.name then
    return string.format("ipairs(%s)", self:gen(ast.iterable))
  end
  if "if" == ast.name then
    if ast.body then
      return "if " .. self:gen(ast.exp) .. " then " .. self:gen(ast.body) .. " end"
    else
      return "if " .. self:gen(ast.exp) .. " then"
    end
  end
  if "return" == ast.name then
    if ast.arg then
      return "return " .. self:gen(ast.arg)
    else
      return "do return end"
    end
  end
  if "keyword" == ast.name then return ast.keyword end
  if "identifier" == ast.name then return ast.id end
  if "table_new" == ast.name then return inline_push("{}") end
  if "table_at" == ast.name then
    return string.format("%s[%s]",
                         self:gen(ast.tbl), self:gen(ast.key))
  end
  if "table_put" == ast.name then
    return string.format(
      "%s[%s]=%s",
      self:gen(ast.tbl), self:gen(ast.key), self:gen(ast.value))
  end
  if "func_call" == ast.name then
    local params = ""
    for i, p in ipairs(ast.args) do
      params = params .. self:gen(p)
      if i < #ast.args then
        params = params .. ","
      end
    end
    return string.format("%s(%s)", ast.func_name, params)
  end
  if "func_header" == ast.name then
    local prefix = ""
    if not ast.global then prefix = "local " end
    local result = string.format("%sfunction %s(", prefix, ast.func_name)
    for i, p in ipairs(ast.params) do
      result = result .. p
      if i < #ast.params then result = result .. "," end
    end
    return result .. ")"
  end
  if "end_func" == ast.name then
    return "end"
  end
  error("Unknown AST: " .. tostring(ast) ..
        " with name: " .. tostring(ast.name))
end

return CodeGen
end
end

do
local _ENV = _ENV
package.preload[ "compiler" ] = function( ... ) local arg = _G.arg;
local macros = require("macros")
local Dict = require("dict")
local Parser = require("parser")
local LineMapping = require("line_mapping")
local Output = require("output")
local Source = require("source")
local Env = require("env")
local interop = require("interop")
local ast = require("ast")
local utils = require("utils")

local Compiler = {}
local marker = "<<equinox:"

function Compiler:new(optimizer, codegen)
  local obj = {
    parser = nil,
    source = Source:empty(),
    output = nil,
    chunks = {},
    code_start = 1,
    line_mapping = LineMapping:new(),
    env = nil,
    root_env = Env:new(nil, "root"),
    state = {},
    optimizer = optimizer,
    codegen = codegen,
    dict = Dict:new()
  }
  setmetatable(obj, {__index = self})
  obj.root_env:def_var_unsafe("true", "true")
  obj.root_env:def_var_unsafe("false", "false")
  obj.root_env:def_var_unsafe("nil", "NIL")
  obj:reset_state()
  return obj
end

function Compiler:reset_state()
  self.env = self.root_env
  self.state = {sequence = 1, do_loop_nesting = 1, last_word = nil}
end

function Compiler:init(source)
  self.source = source
  self.parser = Parser:new(source.text)
  self.output = Output:new(marker .. self.source.name .. ">>")
  self.output:append(
    "local stack, aux = require(\"stack\"), require(\"stack_aux\")")
  self.output:new_line()
  self.ast = {}
  self.code_start = self.output:size()
  if self.source.type == "chunk" then
    self.chunks[self.source.name] = self.source
  end
end

function Compiler:new_env(name)
  self.env = Env:new(self.env, name)
end

function Compiler:remove_env(name, item)
  if name and self.env.name ~= name then
    self:err("Incorrect nesting: " .. name, item)
  end
  if self.env.parent then
    self.env = self.env.parent
  else
    error("cannot drop root environment")
  end
end

function Compiler:def_var(name)
  return self.env:def_var(name)
end

function Compiler:def_global(name)
  return self.root_env:def_var(name)
end

function Compiler:has_var(name)
  return self.env:has_var(name)
end

function Compiler:find_var(name)
  return self.env:find_var(name)
end

function Compiler:var_names()
  return self.env:var_names()
end

function Compiler:word()
  local item = self:next_item()
  if item then
    return item.token
  else
    return nil
  end
end

function Compiler:next_item()
  return self.parser:next_item()
end

function Compiler:find(forth_name)
  return self.dict:find(forth_name)
end

function Compiler:reveal(lua_name)
  self.dict:reveal(lua_name)
end

function Compiler:next_chr()
  return self.parser:next_chr()
end

function Compiler:peek_chr()
  return self.parser:peek_chr()
end

function Compiler:word_list()
  return self.dict:word_list()
end

function Compiler:alias(lua_name, forth_alias)
  return self.dict:def_lua_alias(lua_name, forth_alias)
end

function Compiler:def_word(alias, name, immediate, hidden)
  self.dict:def_word(alias, name, immediate, hidden)
end

function Compiler:err(message, item)
  self.source:show_lines(item.line_number, 1)
  self:reset_state()
  error(message .. " at line: " .. item.line_number)
end

function Compiler:warn(message, item)
  print("[WARN] " .. message .. " at line: " .. item.line_number)
end

function Compiler:exec_macro(item)
  local mod, fun = self.dict:find(item.token).lua_name:match("^(.-)%.(.+)$")
  if mod == "macros" and type(macros[fun]) == "function" then
    return macros[fun](self, item)
  else
    self:err("Unknown macro: " .. item.token, item)
  end
end

function Compiler:add_ast_nodes(nodes, item)
  if #nodes > 0 then
    for i, each in ipairs(nodes) do
      self:add_ast_nodes(each, item)
    end
  else
    nodes.forth_line_number = item.line_number
    table.insert(self.ast, nodes) -- single node
  end
end

function Compiler:valid_ref(name)
  return self.env:has_var(name) or interop.resolve_lua_obj(name)
end

function Compiler:compile_token(item)
  if item.kind == "symbol" then
    return ast.push(ast.literal("string", item.token:sub(2)))
  end
  if item.kind == "number" then
    return ast.push(ast.literal(item.kind, tonumber(item.token)))
  end
  if item.kind == "string" then
    return ast.push(ast.literal(item.kind, item.token:sub(2, -2)))
  end
  if item.kind == "word" then
    local word = self.dict:find(item.token)
    if word and word.immediate then
      return self:exec_macro(item)
    end
    if word and word.is_lua_alias then
      -- Prevent optimizer to overwrite original definition
      return utils.deepcopy(word.lua_name)
    end
    if self.env:has_var(item.token) then -- Forth variable
      return ast.push(
        ast.identifier(self.env:find_var(item.token).lua_name))
    end
    if word then -- Regular Forth word
      return ast.func_call(word.lua_name)
    end
    if interop.dot_or_colon_notation(item.token) then
      -- Table lookup: math.pi or tbl.key or method call a:b a:b.c
      local parts = interop.explode(item.token)
      local name = parts[1]
      if self:valid_ref(name) then
        if self.env:has_var(name) then
          parts[1] = self.env:find_var(name).lua_name
        end
        -- This can result multiple values, like img:getDimensions,
        -- a single value like tbl.key or str:upper, or void like img:draw
        if interop.is_lua_prop_lookup(item.token) then
          return ast.push(ast.identifier(interop.join(parts)))
        else
          return ast.push_many(ast.identifier(interop.join(parts)))
        end
      else
        self:err("Unkown variable: " .. name .. " in expression: " .. item.token, item)
      end
    end
    if interop.resolve_lua_obj(item.token) then
      -- Lua globals from _G, such as math, table, io
      return ast.push(ast.identifier(item.token))
    end
  end
  self:err("Unknown token: " .. item.token .. " kind: " .. item.kind, item)
end

function Compiler:compile(source)
  self:init(source)
  local item = self.parser:next_item()
  while item do
    local node = self:compile_token(item)
    if node then self:add_ast_nodes(node, item) end
    item = self.parser:next_item()
  end
  self.ast = self.optimizer:optimize_iteratively(self.ast)
  return self:generate_code()
end

function Compiler:generate_code()
  for i, ast in ipairs(self.ast) do
    local code = self.codegen:gen(ast)
    if ast.forth_line_number then
      self.line_mapping:map_target_to_source(
        self.source.name,
        ast.forth_line_number,
        self.output.line_number)
    end
    if ast.name == "func_header" then
      local word = self.dict:find_by_lua_name(ast.func_name)
      -- methods are not stored in dict
      if word then word.line_number = self.output.line_number end
    end
    self.output:append(code)
    self.output:new_line()
    if ast.name == "end_func" then
      local word = self.dict:find_by_lua_name(ast.func_name)
      if word then -- methods are not stored in dict
        word.code = string.gsub(
          self.output:text(word.line_number), "[\n\r]+$", "")
      end
    end
  end
  return self.output
end

function Compiler:traceback(err)
  local info
  local file = "N/A"
  for level = 1, math.huge do
    info = debug.getinfo(level, "Sl")
    if not info then
      break
    end
    if info.source and
       info.currentline > 0 and
       info.source:sub(1, #marker) == marker
    then
      file = info.source:match(marker .. "(.-)>>")
      local src_line_num =
        self.line_mapping:resolve_target(file, info.currentline)
      if src_line_num then
        io.stderr:write(string.format(
                "  File \"%s\", line %d (%d)\n", file, src_line_num, info.currentline))
        if utils.exists(file) then
          Source:from_file(file):show_lines(src_line_num, 1)
        elseif self.chunks[file] then
          self.chunks[file]:show_lines(src_line_num, 1)
        end
      end
    end
  end
  return err
end

function Compiler:eval_file(path, log_result)
  return self:_eval(Source:from_file(path), log_result)
end

function Compiler:eval_text(text, log_result)
  return self:_eval(Source:from_text(text), log_result)
end

function Compiler:compile_and_load(source, log_result) -- used by REPL for multiline
  local out = self:compile(source)
  if log_result then
    io.write(self.output:text(self.code_start))
  end
  return out:load()
end

function Compiler:_eval(source, log_result)
  local code, err = self:compile_and_load(source, log_result, path)
  if err then
    self:traceback(err) -- error during load
    error(err)
  end
  local success, result = xpcall(code, function(e) return self:traceback(e) end)
  if success then
    return result
  else
    error(result) -- error during execute
  end
end

return Compiler
end
end

do
local _ENV = _ENV
package.preload[ "console" ] = function( ... ) local arg = _G.arg;
local console = {}

local is_windows = (os.getenv("OS") and string.find(os.getenv("OS"), "Windows"))
  or package.config:sub(1,1) == '\\'

console.RED    = "\27[91m"
console.GREEN  = "\27[92m"
console.CYAN   = "\27[1;96m"
console.PURPLE = "\27[1;95m"
console.RESET  = "\27[0m"

function console.message(text, color, no_cr)
  if no_cr then
    new_line = ""
  else
    new_line = "\n"
  end
  if is_windows then
    color = ""
    reset = ""
  else
    reset = console.RESET
  end
  io.write(string.format("%s%s%s%s", color, text, reset, new_line))
end

function console.colorize(text, color)
  if is_windows then
    return text
  else
    return string.format("%s%s%s", color, text, console.RESET)
  end
end

return console
end
end

do
local _ENV = _ENV
package.preload[ "dict" ] = function( ... ) local arg = _G.arg;
local interop = require("interop")

local Dict = {}

function Dict:new()
  local obj = {words = {}}
  setmetatable(obj, {__index = self})
  obj:init()
  return obj
end

local function entry(forth_name, lua_name, immediate, is_lua_alias, hidden)
  return {
    forth_name = forth_name,
    lua_name = lua_name,
    immediate = immediate,
    is_lua_alias = is_lua_alias,
    hidden = hidden,
    line_number = nil
  }
end

function Dict:def_word(forth_name, lua_name, immediate, hidden)
  table.insert(self.words,
               entry(forth_name, lua_name, immediate, false, hidden))
end

function Dict:def_macro(forth_name, lua_name)
  self:def_word(forth_name, lua_name, true, false)
end

function Dict:def_lua_alias(lua_name, forth_name)
  table.insert(self.words,
               entry(forth_name, lua_name, immediate, true, false))
end

function Dict:find(name)
  return self:find_by(
    function (item)
      return item.forth_name == name
    end)
end

function Dict:find_by_lua_name(name)
  return self:find_by(
    function (item)
      return item.lua_name == name
    end)
end

function Dict:find_by(pred)
  for i = #self.words, 1, -1 do
    local each = self.words[i]
    if not each.hidden and pred(each) then
      return each
    end
  end
  return nil
end

function Dict:reveal(name)
  for i = #self.words, 1, -1 do
    local each = self.words[i]
    if each.lua_name == name then
      each.hidden = false
      return
    end
  end
end

function Dict:word_list()
  local result, seen = {}, {}
  for i, each in ipairs(self.words) do
    if not seen[each.forth_name] and
       not each.hidden
    then
      if each.is_lua_alias or
         each.immediate or
         interop.resolve_lua_func(each.lua_name)
      then
        table.insert(result, each.forth_name)
      end
      seen[each.forth_name] = true
    end
  end
  return result
end

function Dict:init()
  self:def_macro("+", "macros.add")
  self:def_macro("-", "macros.sub")
  self:def_macro("*", "macros.mul")
  self:def_macro("/", "macros.div")
  self:def_macro("%", "macros.mod")
  self:def_macro(".", "macros.dot")
  self:def_macro("cr", "macros.cr")
  self:def_macro("=", "macros.eq")
  self:def_macro("!=", "macros.neq")
  self:def_macro(">", "macros.lt")
  self:def_macro(">=", "macros.lte")
  self:def_macro("<", "macros.gt")
  self:def_macro("<=", "macros.gte")
  self:def_macro("swap", "macros.swap")
  self:def_macro("over", "macros.over")
  self:def_macro("rot", "macros.rot")
  self:def_macro("-rot", "macros.mrot")
  self:def_macro("nip", "macros.nip")
  self:def_macro("drop", "macros.drop")
  self:def_macro("dup", "macros.dup")
  self:def_macro("2dup", "macros.dup2")
  self:def_macro("tuck", "macros.tuck")
  self:def_macro("depth", "macros.depth")
  self:def_macro("pick", "macros.pick")
  self:def_macro("roll", "macros.roll")
  self:def_macro("adepth", "macros.adepth")
  self:def_macro("not", "macros._not")
  self:def_macro("and", "macros._and")
  self:def_macro("or", "macros._or")
  self:def_macro("..", "macros.concat")
  self:def_macro(">a", "macros.to_aux")
  self:def_macro("a>", "macros.from_aux")
  self:def_macro("{}", "macros.new_table")
  self:def_macro("[]", "macros.new_table")
  self:def_macro("size", "macros.table_size")
  self:def_macro("@", "macros.table_at")
  self:def_macro("!", "macros.table_put")
  self:def_macro("words", "macros.words")
  self:def_macro("exit", "macros._exit")
  self:def_macro("return", "macros.ret")
  self:def_macro("if", "macros._if")
  self:def_macro("then", "macros._then")
  self:def_macro("else", "macros._else")
  self:def_macro("begin", "macros._begin")
  self:def_macro("until", "macros._until")
  self:def_macro("while", "macros._while")
  self:def_macro("repeat", "macros._repeat")
  self:def_macro("again", "macros._again")
  self:def_macro("case", "macros._case")
  self:def_macro("of", "macros._of")
  self:def_macro("endof", "macros._endof")
  self:def_macro("endcase", "macros._endcase")
  self:def_macro("do", "macros._do")
  self:def_macro("loop", "macros._loop")
  self:def_macro("ipairs:", "macros.for_ipairs")
  self:def_macro("pairs:", "macros.for_pairs")
  self:def_macro("iter:", "macros.for_each")
  self:def_macro("to:", "macros._to")
  self:def_macro("step:", "macros._step")
  self:def_macro("#(", "macros.arity_call_lua")
  self:def_macro("->", "macros.assignment")
  self:def_macro("var", "macros.var")
  self:def_macro("global", "macros.var_global")
  self:def_macro("(", "macros.comment")
  self:def_macro("\\", "macros.single_line_comment")
  self:def_macro("alias:", "macros.def_alias")
  self:def_macro(":", "macros.colon")
  self:def_macro("::", "macros.local_colon")
  self:def_macro(";", "macros.end_word")
  self:def_macro("recursive", "macros.reveal")
  self:def_macro("exec", "macros.exec")
  self:def_macro("'", "macros.tick")
  self:def_macro("$", "macros.keyval")
  self:def_macro("(:", "macros.formal_params")
  self:def_macro("block", "macros.block")
  self:def_macro("end", "macros._end")
  self:def_macro("see", "macros.see")
end

return Dict
end
end

do
local _ENV = _ENV
package.preload[ "env" ] = function( ... ) local arg = _G.arg;
local interop = require("interop")

local Env = {}

function Env:new(parent, name)
  local obj = {parent = parent,
               name = name,
               vars = {}}
  setmetatable(obj, {__index = self})
  return obj
end

function Env:def_var_unsafe(forth_name, lua_name)
  table.insert(self.vars, {forth_name = forth_name,
                           lua_name = lua_name})
end

function Env:def_var(name)
  local lua_name = interop.sanitize(name)
  self:def_var_unsafe(name, lua_name)
  return lua_name
end

function Env:has_var(forth_name)
  return self:find_var(forth_name) ~= nil
end

function Env:find_var(forth_name)
  for i, each in ipairs(self.vars) do
    if each.forth_name == forth_name then
      return each
    end
  end
  return self.parent and self.parent:find_var(forth_name)
end

function Env:var_names()
  local result
  if not self.parent then
    result = {}
  else
    result = self.parent:var_names()
  end
  for _, each in ipairs(self.vars) do
    table.insert(result, each.forth_name)
  end
  return result
end

return Env
end
end

do
local _ENV = _ENV
package.preload[ "interop" ] = function( ... ) local arg = _G.arg;
local interop = {}

function interop.resolve_lua_obj(name)
  local obj = _G
  for part in name:gmatch("[^%.]+") do
    obj = obj[part]
    if obj == nil then return nil end
  end
  return obj
end

function interop.resolve_lua_func(name)
  local obj = interop.resolve_lua_obj(name)
  if obj and type(obj) == "function" then
    return obj
  else
    return nil
  end
end

function interop.table_name(token)
  return string.match(token, "^[^.]+")
end

function interop.explode(token)
  local result = {}
  for part, sep in token:gmatch("([^:%.]+)([:%.]?)") do
    table.insert(result, part)
    if sep ~= "" then
      table.insert(result, sep)
    end
  end
  return result
end

function interop.join(parts)
  local exp = ""
  for i, each in ipairs(parts) do
    exp = exp .. each
    if each ~= ":" and
        each ~= "." and
        parts[i-1] == ":"
    then
      exp = exp .. "()"
    end
  end
  return exp
end

function interop.is_lua_prop_lookup(token)
  return token:sub(2, #token -1):find("[.]")
end

function interop.dot_or_colon_notation(token)
  return token:sub(2, #token -1):find("[.:]")
end

function interop.is_valid_lua_identifier(name)
  local keywords = {
      ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true,
      ["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["goto"] = true,
      ["if"] = true, ["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true,
      ["or"] = true, ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
      ["until"] = true, ["while"] = true }
  if keywords[name] then
      return false
  end
  return name:match("^[a-zA-Z_][a-zA-Z0-9_]*$") ~= nil
end

function interop.sanitize(str)
  str = str:gsub("-", "_mi_")
    :gsub("%+", "_pu_")
    :gsub("%%", "_pe_")
    :gsub("/", "_fs_")
    :gsub("\\", "_bs_")
    :gsub("~", "_ti_")
    :gsub("#", "_hs_")
    :gsub("%*", "_sr_")
    :gsub(";", "_sc_")
    :gsub("&", "_an_")
    :gsub("|", "_or_")
    :gsub("@", "_at_")
    :gsub("`", "_bt_")
    :gsub("=", "_eq_")
    :gsub("'", "_sq_")
    :gsub('"', "_dq_")
    :gsub("?", "_qe_")
    :gsub("!", "_ex_")
    :gsub(",", "_ca_")
    :gsub("%>", "_gt_")
    :gsub("%<", "_lt_")
    :gsub("%{", "_c1_")
    :gsub("%}", "_c2_")
    :gsub("%[", "_b1_")
    :gsub("%]", "_b2_")
    :gsub("%(", "_p1_")
    :gsub("%(", "_p2_")
  if str:match("^%d+") then
    str = "_" .. str
  end
  -- . and : are only allowed at the beginning or end
  if str:match("^%.") then str = "dot_" .. str:sub(2) end
  if str:match("^%:") then str = "col_" .. str:sub(2) end
  if str:match("%.$") then str = str:sub(1, #str -1) .. "_dot" end
  if str:match("%:$") then str = str:sub(1, #str -1) .. "_col" end
  return str
end

return interop
end
end

do
local _ENV = _ENV
package.preload[ "line_mapping" ] = function( ... ) local arg = _G.arg;
local LineMapping = {}

function LineMapping:new()
  local obj = {
    mapping = {},
  }
  setmetatable(obj, {__index = self})
  return obj
end

function LineMapping:map_target_to_source(tag, source_line_num, target_line_num)
  if not self.mapping[tag] then
    self.mapping[tag] = {}
  end
  self.mapping[tag][target_line_num] = source_line_num
end

function LineMapping:resolve_target(tag, target_line_num)
  local mapping = self.mapping[tag]
  if mapping then
    return mapping[target_line_num]
  end
  return nil
end

return LineMapping
end
end

do
local _ENV = _ENV
package.preload[ "ln_repl_backend" ] = function( ... ) local arg = _G.arg;
local console = require("console")
local utils = require("utils")
local ln = require("linenoise")

ln.enableutf8()

local Backend = {}

function Backend:new(compiler, history_file, commands)
  local obj = {compiler = compiler,
               input = "",
               commands = commands,
               history_file = history_file}
  setmetatable(obj, {__index = self})
  if history_file then
    ln.historyload(history_file)
  end
  obj:setup()
  return obj
end

function Backend:setup()
  ln.setcompletion(function(completion, str)
    for _, match in ipairs(self:completer(str)) do
      completion:add(match)
    end
  end)
end

local function add_completions(input, words, result)
  for _, word in ipairs(words) do
    local before, after = input:match("^(.*)%s(.*)$")
    if not after then
      after = input
      before = ""
    else
      before = before .. " "
    end
    if utils.startswith(word, after) then
      table.insert(result, before .. word)
    end
  end
end

local function resolve(input)
  local obj = _G
  for part in input:gmatch("[^%.]+") do
    if obj[part] then
      obj = obj[part]
    else
      return obj
    end
  end
  return obj
end

local function add_props(input, result)
  local obj = resolve(input)
  if type(obj) ~= "table" or obj == _G then
    return
  end
  local prefix = input:match("(.+%.)")
  if not prefix then prefix = "" end
  local last = input:match("[^%.]+$")
  for key, val in pairs(obj) do
    if not last or utils.startswith(key, last) then
      table.insert(result, prefix .. key)
    end
  end
end

local function add_commands(input, result, commands)
  for _, cmd in ipairs(commands) do
    if utils.startswith(cmd, input) then
      table.insert(result, cmd)
    end
  end
end

local function modules()
  local result = {}
  for key, val in pairs(_G) do
    if type(val) == "table" then
      table.insert(result, key)
    end
  end
  return result
end

function Backend:completer(input)
  local matches = {}
  add_completions(input, self.compiler:word_list(), matches)
  add_completions(input, self.compiler:var_names(), matches)
  add_commands(input, matches, self.commands)
  if input:find("%.") then
    add_props(input, matches)
  else
    add_completions(input, modules(), matches)
  end
  return utils.unique(matches)
end

function Backend:prompt()
  if self.multi_line then
    return "..."
  else
    return "#"
  end
end

function Backend:save_history(input)
  if self.history_file then
    ln.historyadd(input)
    ln.historysave(self.history_file)
  end
end

function Backend:read_line(prompt)
  return utils.trim(ln.linenoise(prompt .. " "))
end

function Backend:read()
  local prompt = console.colorize(self:prompt(), console.PURPLE)
  if self.multi_line then
    self.input = self.input .. "\n" .. self:read_line(prompt)
  else
    self.input = self:read_line(prompt)
  end
  return self.input
end

function Backend:set_multiline(bool)
  self.multi_line = bool
  ln.setmultiline(bool)
end

return Backend
end
end

do
local _ENV = _ENV
package.preload[ "macros" ] = function( ... ) local arg = _G.arg;
local aux = require("stack_aux")
local interop = require("interop")
local ast = require("ast")
local unpack = table.unpack or unpack

local macros = {}

function macros.add()
  return ast.push(ast.bin_op("+", ast.pop(), ast.pop()))
end

function macros.mul()
  return ast.push(ast.bin_op("*", ast.pop(), ast.pop()))
end

function macros.sub()
  return ast.push(ast.bin_op("-", ast.pop2nd(), ast.pop()))
end

function macros.div()
  return ast.push(ast.bin_op("/", ast.pop2nd(), ast.pop()))
end

function macros.mod()
  return ast.push(ast.bin_op("%", ast.pop2nd(), ast.pop()))
end

function macros.eq()
  return ast.push(ast.bin_op("==", ast.pop(), ast.pop()))
end

function macros.neq()
  return ast.push(ast.bin_op("~=", ast.pop(), ast.pop()))
end

function macros.lt()
  return ast.push(ast.bin_op(">", ast.pop2nd(), ast.pop()))
end

function macros.lte()
  return ast.push(ast.bin_op(">=", ast.pop2nd(), ast.pop()))
end

function macros.gt()
  return ast.push(ast.bin_op("<", ast.pop2nd(), ast.pop()))
end

function macros.gte()
  return ast.push(ast.bin_op("<=", ast.pop2nd(), ast.pop()))
end

function macros._not()
  return ast.push(ast.unary_op("not", ast.pop()))
end

function macros._and()
  return ast.stack_op("_and")
end

function macros._or()
  return ast.stack_op("_or")
end

function macros.concat()
  return ast.push(ast.bin_op("..", ast.pop2nd(), ast.pop()))
end

function macros.new_table()
  return ast.new_table()
end

function macros.table_size()
  return ast.push(ast.unary_op("#", ast.pop()))
end

function macros.table_at()
  return ast.push(ast.table_at(ast.pop2nd(), ast.pop()))
end

function macros.table_put()
  return ast.table_put(ast.pop3rd(), ast.pop2nd(), ast.pop())
end

function macros.depth()
  return ast.push(ast.stack_op("depth"))
end

function macros.adepth()
  return ast.push(ast.aux_op("depth"))
end

function macros.dup()
  return ast.stack_op("dup")
end

function macros.drop()
  return ast.pop()
end

function macros.over()
  return ast.stack_op("over")
end

function macros.nip()
  return ast.stack_op("nip")
end

function macros.dup2()
  return ast.stack_op("dup2")
end

function macros.mrot()
  return ast.stack_op("mrot")
end

function macros.tuck()
  return ast.stack_op("tuck")
end

function macros.rot()
  return ast.stack_op("rot")
end

function macros.swap()
  return ast.stack_op("swap")
end

function macros.to_aux()
  return ast.aux_push(ast.pop())
end

function macros.from_aux()
  return ast.push(ast.aux_op("pop"))
end

function macros.pick()
  return ast.push(ast.func_call("pick", ast.pop()))
end

function macros.roll()
  return ast.func_call("roll", ast.pop())
end

function macros.dot()
  return {
    ast.func_call("io.write", ast.func_call("tostring", ast.pop())),
    ast.func_call("io.write", ast.str(" "))
  }
end

function macros.cr()
  return ast.func_call("print")
end

function macros.def_alias(compiler, item)
  local forth_name = compiler:word()
  local alias = {}
  if not forth_name then
    compiler:err("Missing alias name", item)
  end

  repeat
    local exp = compiler:next_item()
    if exp then
      table.insert(alias, compiler:compile_token(exp))
    end
  until not exp
    or compiler:peek_chr() == "\n"
    or compiler:peek_chr() == "\r"

  if #alias == 0 then
    compiler:err("Missing alias body", item)
  end
  compiler:alias(alias, forth_name)
end

local function def_word(compiler, is_global, item)
  local forth_name = compiler:word()
  if not forth_name then
    compiler:err("Missing name for colon definition.", item)
  end
  local lua_name = interop.sanitize(forth_name)
  if select(2, forth_name:gsub("%:", "")) > 1 or
     select(2, forth_name:gsub("%.", "")) > 1
  then
    compiler:err("Name '" .. forth_name .. "' " ..
                 "can't contain multiple . or : characters.", item)
  end
  if interop.dot_or_colon_notation(forth_name) then -- method syntax
    local parts = interop.explode(forth_name)
    local obj = parts[1]
    local method = parts[3] -- parts[2] is expected to be . or :
    if not interop.is_valid_lua_identifier(method) then
      compiler:err("Name '" .. method .. "' " ..
                   "is not a valid name for dot or colon notation.", item)
    end
    if not compiler:has_var(obj) then
      compiler:warn("Unknown object: '" .. tostring(obj) .. "'" ..
          "in method definition: " .. forth_name, item)
    end
    if forth_name:find(":") then
      compiler:def_var("self")
    end
  elseif compiler:find(forth_name) then -- Regular Forth word
    -- emulate hyper static glob env for funcs but not for methods
    lua_name = lua_name .. "__s" .. compiler.state.sequence
    compiler.state.sequence = compiler.state.sequence + 1
  end
  if not interop.dot_or_colon_notation(forth_name) then
    compiler:def_word(forth_name, lua_name, false, true)
  end
  compiler:new_env("colon_" .. lua_name)
  local header = ast.func_header(lua_name, is_global)
  if compiler.state.last_word then
    compiler:err("Word definitions cannot be nested.", item)
  else
    compiler.state.last_word = header
  end
  return header
end

function macros.colon(compiler, item)
  return def_word(compiler, true, item)
end

function macros.local_colon(compiler, item)
  return def_word(compiler, false, item)
end

function macros.tick(compiler, item)
  local name = compiler:word()
  if not name then
    compiler:err("A word is required for '", item)
  end
  local word = compiler:find(name)
  if not word then
    compiler:err(name .. " is not found in dictionary", item)
  elseif word.immediate then
    compiler:err("' cannot be used on a macro: " .. name, item)
  elseif word.is_lua_alias then
    compiler:err("' cannot be used on an alias: " .. name, item)
  end
  return ast.push(ast.identifier(word.lua_name))
end

function macros.exec(compiler)
  return ast.func_call("pop()")
end

function macros.ret(compiler)
  return ast._return(ast.pop())
end

function macros.comment(compiler)
  repeat
    local ch = compiler:next_chr()
  until ")" == ch or "" == ch
end

function macros.single_line_comment(compiler)
  repeat
    local ch = compiler:next_chr()
  until "\n" == ch or "\r" == ch or "" == ch
  if ch == "\r" and compiler:peek_chr() == "\n" then
    compiler:next_chr()
  end
end

local function is_valid_exp(exp, compiler)
  local name = exp
  if interop.dot_or_colon_notation(exp) then
    name = interop.explode(exp)[1]
  end
  return compiler:valid_ref(name) or compiler:find(name)
end

function macros.arity_call_lua(compiler, item)
  local func  = compiler:word()
  if not is_valid_exp(func, compiler) then
    compiler:err("Unkown function or word: " .. func, item)
  end
  local numret = -1
  local arity = 0
  local token = compiler:word()
  if token ~= ")" then
    arity = tonumber(token)
    if not arity or arity < 0 then
      compiler:err("expected arity number, got '"
                   .. tostring(token) .. "'", item)
    end
    token = compiler:word()
    if token ~= ")" then
      numret = tonumber(token)
      if not numret or numret < -1 or numret > 1 then
        compiler:err("expected number of return values (0/1/-1), got '"
                     .. tostring(token) .. "'", item)
      end
      token = compiler:word()
      if token ~= ")" then
        compiler:err("expected closing ), got '"
                     .. tostring(token) .. "'", item)
      end
    end
  end
  local params = {}
  local stmts = {}
  if arity > 0 then
    for i = 1, arity do
      table.insert(params,
        ast.identifier(ast.gen_id("__p")))
    end
    for i = arity, 1, -1 do -- reverse parameter order
      table.insert(stmts,
        ast.init_local(params[i].id, ast.pop()))
    end
  end
  if numret == 0 then
    table.insert(stmts, ast.func_call(func, unpack(params)))
  elseif numret == 1 then
    table.insert(stmts, ast.push(
                   ast.func_call(func, unpack(params))))
  elseif numret == -1 then
    table.insert(stmts, ast.push_many(
                   ast.func_call(func, unpack(params))))
  else
    compiler:err("Invalid numret:" .. tostring(numret), item)
  end
  return stmts
end

function macros.var(compiler, item)
  local name = compiler:word()
  if name then
    return ast.def_local(compiler:def_var(name))
  else
    compiler:err("Missing variable name.", item)
  end
end

function macros.var_global(compiler, item)
  local name = compiler:word()
  if name then
    return ast.def_global(compiler:def_global(name))
  else
    compiler:err("Missing variable name.", item)
  end
end

local function valid_tbl_assignment(compiler, name)
  if interop.is_lua_prop_lookup(name) then
    local tbl = interop.table_name(name)
    return compiler:has_var(tbl)
      or interop.resolve_lua_obj(name)
  end
  return false
end

function macros.assignment(compiler, item)
  local name = compiler:word()
  if not name then
    compiler:err("Missing variable name.", item)
  end
  if name == "var" then
    -- declare and assign of a new var
    name = compiler:word()
    if not name then
      compiler:err("Missing variable name.", item)
    end
    return ast.init_local(compiler:def_var(name), ast.pop())
  elseif name == "global" then
    -- declare and assign of a new global
    name = compiler:word()
    if not name then
      compiler:err("Missing variable name.", item)
    end
    return ast.init_global(compiler:def_global(name), ast.pop())
  else
    -- assignment of existing var
    if compiler:has_var(name) then
      return ast.assignment(
        compiler:find_var(name).lua_name, ast.pop())
    elseif valid_tbl_assignment(compiler, name) then -- 123 -> tbl.x
      local parts = interop.explode(name)
      if compiler:has_var(parts[1]) then
        parts[1] = compiler:find_var(parts[1]).lua_name
        return ast.assignment(interop.join(parts), ast.pop())
      else
        return ast.assignment(name, ast.pop())
      end
    else
      compiler:err("Undeclared variable: " .. name, item)
    end
  end
end

function macros._if(compiler)
  compiler:new_env('IF')
  return ast._if(ast.pop())
end

function macros._else()
  return ast.keyword("else")
end

function macros._then(compiler, item)
  compiler:remove_env('IF', item)
  return ast.keyword("end")
end

function macros._begin(compiler)
  -- begin..until / begin..again / begin..while..repeat
  compiler:new_env('BEGIN_LOOP')
  return ast._while(ast.literal("boolean", "true"))
end

function macros._again(compiler, item)
  compiler:remove_env('BEGIN_LOOP', item)
  return ast.keyword("end")
end

function macros._repeat(compiler, item)
  compiler:remove_env('BEGIN_LOOP', item)
  return ast.keyword("end")
end

function macros._until(compiler, item)
  compiler:remove_env('BEGIN_LOOP', item)
  return {
    ast._if(ast.pop(), ast.keyword("break")),
    ast.keyword("end")
  }
end

function macros.block(compiler)
  compiler:new_env('BLOCK')
  return ast.keyword("do")
end

function macros._while()
  return ast._if(ast.unary_op("not", ast.pop()), ast.keyword("break"))
end

function macros._case(compiler) -- simulate goto with break, in pre lua5.2 since GOTO was not yet supported
  compiler:new_env('CASE')
  return ast.keyword("repeat")
end

function macros._of(compiler)
  compiler:new_env('OF')
  return {
    ast.stack_op("over"),
    ast._if(ast.bin_op("==", ast.pop(), ast.pop())),
    ast.pop() -- drop selector
  }
end

function macros._endof(compiler, item) -- GOTO endcase
  compiler:remove_env('OF', item)
  return { ast.keyword("break"), ast.keyword("end") }
end

function macros._endcase(compiler, item)
  compiler:remove_env('CASE', item)
  return ast._until(ast.literal("boolean", "true"))
end

function macros._exit()
  return ast._return(nil) -- exit from Forth word
end

function macros._do(compiler)
  local do_loop_vars = {"i", "j", "k"}
  local state = compiler.state
  local loop_var =
    do_loop_vars[((state.do_loop_nesting -1) % #do_loop_vars) +1]
  state.do_loop_nesting = state.do_loop_nesting + 1
  compiler:new_env('DO_LOOP')
  compiler:def_var(loop_var)
  return ast._for(
      loop_var,
      ast.pop(),
      ast.bin_op("-", ast.pop(), ast.literal("number", 1)),
      nil)
end

function macros._loop(compiler, item)
  compiler:remove_env('DO_LOOP', item)
  compiler.state.do_loop_nesting =
    compiler.state.do_loop_nesting - 1
  return ast.keyword("end")
end

function macros.for_ipairs(compiler, item)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  if not var_name1 or not var_name2 then
    compiler:err("ipairs needs two loop variables", item)
  end
  compiler:new_env('IPAIRS_LOOP')
  compiler:def_var(var_name1)
  compiler:def_var(var_name2)
  return ast._foreach(var_name1, var_name2, ast._ipairs(ast.pop()))
end

function macros.for_pairs(compiler, item)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  if not var_name1 or not var_name2 then
    compiler:err("pairs needs two loop variables", item)
  end
  compiler:new_env('PAIRS_LOOP')
  compiler:def_var(var_name1)
  compiler:def_var(var_name2)
  return ast._foreach(var_name1, var_name2, ast._pairs(ast.pop()))
end

function macros.for_each(compiler, item)
  local var_name = compiler:word()
  if not var_name then
    compiler:err("iter needs one loop variable", item)
  end
  compiler:new_env('ITER_LOOP')
  compiler:def_var(var_name)
  return ast._foreach(var_name, nil, ast.pop())
end

function macros._to(compiler, item)
  local loop_var = compiler:word()
  if not loop_var then
    compiler:err("to loop needs a loop variable.", item)
  end
  compiler:new_env('TO_LOOP')
  compiler:def_var(loop_var)
  return ast._for(loop_var, ast.pop2nd(), ast.pop(), nil)
end

function macros._step(compiler, item)
  local loop_var = compiler:word()
  if not loop_var then
    compiler:err("step loop needs a loop variable.", item)
  end
  compiler:new_env('STEP_LOOP')
  compiler:def_var(loop_var)
  return ast._for(loop_var, ast.pop3rd(), ast.pop2nd(), ast.pop(), nil)
end

function macros._end(compiler)
  compiler:remove_env() -- can belong to multiple
  return ast.keyword("end")
end

function macros.end_word(compiler, item)
  if not compiler.state.last_word then
    compiler:err("Unexpected semicolon", item)
  end
  local name = compiler.state.last_word.func_name
  macros.reveal(compiler, item)
  compiler.state.last_word = nil
  compiler:remove_env()
  return ast.end_func(name)
end

function macros.see(compiler, item)
  local name = compiler:word()
  if not name then
    compiler:err("See needs a word name", item)
  end
  local word = compiler:find(name)
  if not word then
    compiler:err(name .. " is not found in dictionary", item)
  elseif word.immediate then
    print("N/A. Macro (immediate word)")
  elseif word.is_lua_alias then
    print("N/A. Alias")
  else
    print(word.code)
  end
end

function macros.keyval(compiler)
  local name = compiler:word()
  return {
    ast.push(ast.str(name)),
    ast.push(ast.identifier(name))
  }
end

function macros.formal_params(compiler, item)
  if not compiler.state.last_word then
    compiler:err("Unexpected (:", item)
  end
  local func_header = compiler.state.last_word
  local param_name = compiler:word()
  while param_name ~= ":)" do
    compiler:def_var(param_name)
    table.insert(func_header.params, param_name)
    param_name = compiler:word()
  end
  return result
end

function macros.reveal(compiler, item)
  if not compiler.state.last_word then
    compiler:err("Reveal must be used within a word definition.", item)
  end
  compiler:reveal(compiler.state.last_word.func_name)
end

function macros.words(compiler)
  for i, each in ipairs(compiler:word_list()) do
    io.write(each .. " ")
  end
  print()
end

return macros
end
end

do
local _ENV = _ENV
package.preload[ "output" ] = function( ... ) local arg = _G.arg;
local Output = {}

function Output:new(name)
  local obj = {lines = {""}, line_number = 1, name = name}
  setmetatable(obj, {__index = self})
  return obj
end

function Output:append(str)
  self.lines[self:size()] = self.lines[self:size()] .. str
end

function Output:new_line()
  self.line_number = self.line_number +1
  table.insert(self.lines, "")
end

function Output:size()
  return #self.lines
end

function Output:text(from)
  return table.concat(self.lines, "\n", from)
end

function Output:load()
  local text = self:text()
  if loadstring then
    return loadstring(text, self.name)
  else -- Since Lua 5.2, loadstring has been replaced by load.
    return load(text, self.name)
  end
end

return Output
end
end

do
local _ENV = _ENV
package.preload[ "parser" ] = function( ... ) local arg = _G.arg;
local interop = require("interop")

local Parser = {}

function Parser:new(source)
  local obj = {index = 1,
               line_number = 1,
               source = source}
  setmetatable(obj, {__index = self})
  return obj
end

function Parser:parse_all()
  local result = {}
  local item = self:next_item()
  while item do
    table.insert(result, item)
    item = self:next_item()
  end
  return result
end

local function is_quote(chr)
  return chr:match('"')
end

local function is_escape(chr)
  return chr:match("\\")
end

local function is_whitespace(chr)
  return chr:match("%s")
end

function Parser:next_item()
  local token = ""
  local begin_str = false
  local stop = false
  local kind = "word"
  while not self:ended() and not stop do
    local chr = self:read_chr()
    if is_quote(chr) then
      if begin_str then
        stop = true
      else
        kind = "string"
        begin_str = true
      end
      token = token .. chr
    elseif begin_str
      and is_escape(chr)
      and is_quote(self:peek_chr()) then
      token = token .. chr .. self:read_chr() -- consume \"
    elseif begin_str and ("\r" == chr or "\n" == chr) then
      error(string.format(
           "Unterminated string: %s at line: %d", token, self.line_number))
    elseif is_whitespace(chr) and not begin_str then
      if #token > 0 then
        self.index = self.index -1 -- don't consume next WS as it breaks single line comment
        stop = true
      else
        self:update_line_number(chr)
      end
    else
      token = token .. chr
    end
  end
  if token == "" then
    return nil -- EOF
  end
  if token:match("^$.+") then kind = "symbol" end
  if tonumber(token) then kind = "number" end
  return {token=token, kind=kind, line_number=self.line_number}
end

function Parser:update_line_number(chr)
  if chr == '\r' then
    if self:peek_chr() == '\n' then self:read_chr() end
    self.line_number = self.line_number +1
  elseif chr == '\n' then
    self.line_number = self.line_number +1
  end
end

function Parser:next_chr()
  local chr = self:read_chr()
  self:update_line_number(chr)
  return chr
end

function Parser:read_chr()
  local chr = self:peek_chr()
  self.index = self.index + 1
  return chr
end

function Parser:peek_chr()
  return self.source:sub(self.index, self.index)
end

function Parser:ended()
  return self.index > #self.source
end

return Parser
end
end

do
local _ENV = _ENV
package.preload[ "repl" ] = function( ... ) local arg = _G.arg;
local stack = require("stack")
local utils = require("utils")
local console = require("console")
local Source = require("source")

local function load_backend(preferred, fallback)
  local success, mod = pcall(require, preferred)
  if success then
    return mod
  else
    return require(fallback)
  end
end

local Repl = {}

local repl_ext = "repl_ext.eqx"

local commands = {
  bye = "bye",
  help = "help",
  log_on = "log-on",
  log_off = "log-off",
  stack_on = "stack-on",
  stack_off = "stack-off",
  opt_on = "opt-on",
  opt_off = "opt-off",
  load_file = "load-file"
}

function Repl:new(compiler, optimizer)
  local ReplBackend = load_backend("ln_repl_backend", "simple_repl_backend")
  local obj = {backend = ReplBackend:new(
                 compiler,
                 utils.in_home(".equinox_repl_history"),
                 utils.values(commands)),
               compiler = compiler,
               optimizer = optimizer,
               ext_dir = os.getenv("EQUINOX_EXT_DIR") or "./ext",
               always_show_stack = false,
               repl_ext_loaded = false,
               log_result = false }
  setmetatable(obj, {__index = self})
  return obj
end

local messages = {
  "The Prime Directive: Preserve Stack Integrity at All Costs.",
  "Engage warp speed and may your stack never overflow.",
  "Welcome Commander. The stack is ready for your orders.",
  "Our mission is to explore new words and seek out new stack operations.",
  "Welcome, Officer. May your debugging skills be as sharp as a phaser.",
  "Your mission is to PUSH the boundaries of programming.",
  "In the Delta Quadrant every stack operation is a new discovery.",
  "One wrong stack move and your program could warp into an infinite loop.",
  "Take responsibility for your code as errors will affect the entire fleet.",
  "Picard's programming tip: Complexity can be a form of the enemy.",
  "Spock's programming tip: Logic is the foundation of all good code.",
  "Spock's programming tip: Do not let emotion cloud your debugging.",
  "Worf's programming tip: A true programmer fights for correctness.",
  "Worf's programming tip: When facing a bug, fire your phasers at full power.",
  "One misplaced DROP can send your code into warp core breach.",
  "To reach warp speed, the code must be optimized for maximum efficiency.",
  "Working in Forth sometimes feels like working in a Jeffries tube.",
  "A balanced stack is a stable warp core. Keep it well protected.",
  "All systems are stable, commander. Stack integrity is 100%.",
  "Captain, the stack is clear and ready for warp.",
  "Deflector shields holding steady captain, the stack is well protected."
}

math.randomseed(os.time())

function Repl:welcome(version)
  print("Equinox Forth Console (" .. _VERSION .. ") @ Delta Quadrant.")
  print(messages[math.random(1, #messages)])
  console.message(string.format([[
 __________________          _-_
 \__(=========/_=_/ ____.---'---`---.___
            \_ \    \----._________.---/
              \ \   /  /    `-_-'
         ___,--`.`-'..'-_
        /____          (|
              `--.____,-'   v%s
]], version), console.CYAN)
  print("Type 'words' for wordlist, 'bye' to exit or 'help'.")
  print("First time Forth user? Type: load-file tutorial")
end

local function show_help()
  print([[
- log-on "turn on logging"
- log-off "turn off logging"
- opt-on "turn on optimization"
- opt-off "turn off optimization"
- load-file <path> "load an eqx file"
- stack-on "always show stack after each input"
- stack-off "don't show stack after each input"
- bye "exit repl"
- help "show this help"]])
end

function Repl:read()
  return self.backend:read()
end

function Repl:process_commands(input)
  local command = utils.trim(input)
  if command == commands.bye then
    os.exit(0)
  end
  if command == commands.help then
    show_help()
    return true
  end
  if command == commands.log_on then
    self.log_result = true
    print("Log turned on")
    return true
  end
  if command == commands.log_off then
    self.log_result = false
    print("Log turned off")
    return true
  end
  if command == commands.stack_on then
    if self.repl_ext_loaded then
      self.always_show_stack = true
      print("Show stack after input is on")
    else
      print("Requires " .. repl_ext)
    end
    return true
  end
  if command == commands.stack_off then
    self.always_show_stack = off
    print("Show stack after input is off")
    return true
  end
  if command == commands.opt_on then
    self.optimizer:enable(true)
    print("Optimization turned on")
    return true
  end
  if command == commands.opt_off then
    self.optimizer:enable(false)
    print("Optimization turned off")
    return true
  end
  if command:sub(1, #commands.load_file) == commands.load_file
  then
    local path = utils.trim(command:sub(#commands.load_file + 1))
    if path and path ~= "" then
      if not utils.exists(path) and not utils.extension(path) then
        path = path .. ".eqx"
      end
      if not utils.exists(path) and
        not (string.find(path, "/") or
              string.find(path, "\\"))
      then
        path = utils.join(self.ext_dir, path)
      end
      if utils.exists(path) then
        self:safe_call(function() self.compiler:eval_file(path) end)
      else
        print("File does not exist: " .. path)
      end
    else
      print("Missing file path.")
    end
    return true
  end
  return false
end

function Repl:print_err(result)
  console.message("Red Alert: ", console.RED, true)
  print(tostring(result))
end

function Repl:print_ok()
  if depth() > 0 then
    console.message("OK(".. depth()  .. ")", console.GREEN)
    if self.always_show_stack and self.repl_ext_loaded then
      self.compiler:eval_text(".s")
    end
  else
    console.message("OK", console.GREEN)
  end
end

function Repl:safe_call(func)
  local success, result = pcall(func)
  if success then
    self:print_ok()
  else
    self:print_err(result)
  end
end

function Repl:start()
  local ext = utils.file_exists_in_any_of(repl_ext, {self.ext_dir})
  if ext then
    self.compiler:eval_file(ext)
    self.repl_ext_loaded = true
  end
  while true do
    local input = self:read()
    if self:process_commands(input) then
      self.backend:save_history(input)
    else
      local success, result = pcall(function ()
          return self.compiler:compile_and_load(
            Source:from_text(input), self.log_result)
      end)
      if not success then
        self:print_err(result)
      elseif not result then
        self.backend:set_multiline(true)
        self.compiler:reset_state()
      else
        self.backend:set_multiline(false)
        self:safe_call(function() result() end)
        self.backend:save_history(input:gsub("[\r\n]", " "))
      end
    end
  end
end

return Repl
end
end

do
local _ENV = _ENV
package.preload[ "simple_repl_backend" ] = function( ... ) local arg = _G.arg;
local console = require("console")

local Backend = {}

function Backend:new()
  local obj = {input = ""}
  setmetatable(obj, {__index = self})
  return obj
end

function Backend:prompt()
  if self.multi_line then
    return "..."
  else
    return "#"
  end
end

function Backend:save_history(input)
  -- unsupported
end

function Backend:read()
  console.message(self:prompt() .. " ", console.PURPLE, true)
  if self.multi_line then
    self.input = self.input .. "\n" .. io.read()
  else
    self.input = io.read()
  end
  return self.input
end

function Backend:set_multiline(bool)
  self.multi_line = bool
end

return Backend
end
end

do
local _ENV = _ENV
package.preload[ "source" ] = function( ... ) local arg = _G.arg;
local Source = {}

local seq = 1

local function lines_of(input)
  local lines = {}
  for line in input:gmatch("([^\r\n]*)\r?\n?") do
    table.insert(lines, line)
  end
  return lines
end

function Source:new(text, path)
  local obj = {text = text,
               path = path,
               name = nil,
               type = nil,
               lines = lines_of(text)}
  setmetatable(obj, {__index = self})
  if path then
    obj.name = path
    obj.type = "file"
  else
    obj.name = "chunk" .. seq
    seq = seq + 1
    obj.type = "chunk"
  end
  return obj
end

function Source:from_text(text)
  return self:new(text, nil)
end

function Source:empty()
  return self:from_text("")
end

function Source:from_file(path)
  local file = io.open(path, "r")
  if not file then
    error("Could not open file: " .. path)
  end
  local src = self:new(file:read("*a"), path)
  file:close()
  return src
end

function Source:show_lines(src_line_num, n)
  for i = src_line_num - n, src_line_num + n do
    local line = self.lines[i]
    if line then
      local mark = "  "
      if i == src_line_num then mark = "=>" end
      io.stderr:write(string.format("    %s%03d.  %s\n", mark, i , line))
    end
  end
end

return Source
end
end

do
local _ENV = _ENV
package.preload[ "stack" ] = function( ... ) local arg = _G.arg;
local stack
local NIL = {} -- nil cannot be stored in table, use this placeholder
local name = "data-stack"

if table.create then
  stack = table.create(32)
else
  stack = {nil, nil, nil, nil, nil, nil, nil, nil}
end

function push(e)
  if e ~= nil then
    stack[#stack + 1] = e
  else
    stack[#stack + 1] = NIL
  end
end

function push_many(...)
  local args = {...}
  local n = #stack
  for i = 1, #args do
    if args[i] ~= nil then
      stack[n + i] = args[i]
    else
      stack[n + i] = NIL
    end
  end
end

function pop()
  local size = #stack
  if size == 0 then error("Stack underflow: " .. name) end
  local item = stack[size]
  stack[size] = nil
  if item ~= NIL then return item else return nil end
end

function pop2nd()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  local item = stack[n - 1]
  stack[n -1] = stack[n]
  stack[n] = nil
  if item ~= NIL then return item else return nil end
end

function pop3rd()
  local n = #stack
  if n < 3 then error("Stack underflow: " .. name) end
  local item = table.remove(stack, n - 2)
  if item ~= NIL then return item else return nil end
end

function swap()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  stack[n], stack[n - 1] = stack[n - 1], stack[n]
end

function rot()
  local n = #stack
  if n < 3 then error("Stack underflow: " .. name) end
  local new_top = stack[n -2]
  table.remove(stack, n - 2)
  stack[n] = new_top
end

function mrot()
  local n = #stack
  if n < 3 then error("Stack underflow: " .. name) end
  local temp = stack[n]
  stack[n] = nil
  table.insert(stack, n - 2, temp)
end

function over()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  stack[n + 1] = stack[n - 1]
end

function tuck()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  table.insert(stack, n - 1, stack[n])
end

function nip()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  stack[n - 1] = stack[n]
  stack[n] = nil
end

function dup()
  local n = #stack
  if n < 1 then error("Stack underflow: " .. name) end
  stack[n + 1] = stack[n]
end

function dup2()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  local tos1 = stack[n]
  local tos2 = stack[n - 1]
  stack[n + 1] = tos2
  stack[n + 2] = tos1
end

function tos()
  local item = stack[#stack]
  if item == nil then error("Stack underflow: " .. name) end
  if item ~= NIL then return item else return nil end
end

function tos2()
  local item = stack[#stack - 1]
  if item == nil then error("Stack underflow: " .. name) end
  if item ~= NIL then return item else return nil end
end

function _and()
  local a, b = pop(), pop()
  push(a and b)
end

function _or()
  local a, b = pop(), pop()
  push(a or b)
end

function _inc()
  local n = #stack
  if n < 1 then error("Stack underflow: " .. name) end
  stack[n] = stack[n] + 1
end

function _neg()
  local n = #stack
  if n < 1 then error("Stack underflow: " .. name) end
  stack[n] = not stack[n]
end

function depth()
  return #stack
end

function pick(index)
  local item = stack[#stack - index]
  if item == nil then error("Stack underflow: " .. name) end
  if item ~= NIL then return item else return nil end
end

function roll(index)
  if index == 0 then return end
  local n = #stack
  if n <= index then error("Stack underflow: " .. name) end
  local new_top = stack[n -index]
  table.remove(stack, n - index)
  stack[n] = new_top
end

return stack
end
end

do
local _ENV = _ENV
package.preload[ "stack_aux" ] = function( ... ) local arg = _G.arg;
local stack = {}
local NIL = {} -- nil cannot be stored in table, use this placeholder
local name = "aux-stack"

function apush(e)
  if e ~= nil then
    stack[#stack + 1] = e
  else
    stack[#stack + 1] = NIL
  end
end

function apop()
  local size = #stack
  if size == 0 then
    error("Stack underflow: " .. name)
  end
  local item = stack[size]
  stack[size] = nil
  if item ~= NIL then return item else return nil end
end

function adepth()
  return #stack
end

return stack
end
end

do
local _ENV = _ENV
package.preload[ "utils" ] = function( ... ) local arg = _G.arg;
local utils = {}

function utils.trim(str)
  return str:match("^%s*(.-)%s*$")
end

function utils.deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[utils.deepcopy(orig_key)] = utils.deepcopy(orig_value)
    end
    setmetatable(copy, utils.deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function utils.home()
  return os.getenv("USERPROFILE") or os.getenv("HOME")
end

function utils.in_home(file)
  return utils.join(utils.home(), file)
end

function utils.values(tbl)
  local vals = {}
  for k, v in pairs(tbl) do
    table.insert(vals, v)
  end
  return vals
end

function utils.extension(filename)
  return filename:match("^.+(%.[^%.]+)$")
end

function utils.join(dir, child)
  if not dir or "" == dir then return child end
  local sep = ""
  if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then
    sep = package.config:sub(1, 1)
  end
  return dir .. sep .. child
end


function utils.exists(filename)
  local file = io.open(filename, "r")
  if file then
    file:close()
    return true
  else
    return false
  end
end

function utils.file_exists_in_any_of(filename, dirs)
  for i, dir in ipairs(dirs) do
    local path = utils.join(dir, filename)
    if utils.exists(path) then
      return path
    end
  end
  return nil
end

function utils.unique(tbl)
  local seen = {}
  local result = {}
  for _, v in ipairs(tbl) do
    if not seen[v] then
      seen[v] = true
      table.insert(result, v)
    end
  end
  return result
end

function utils.keys(tbl)
  local result = {}
  for key, _ in pairs(tbl) do
    table.insert(result, key)
  end
  return result
end

function utils.startswith(str, prefix)
  return string.sub(str, 1, #prefix) == prefix
end

function utils.module_available(name)
  local ok, _ = pcall(require, name)
  return ok
end

return utils
end
end

__VERSION__="0.1-398"

local Compiler = require("compiler")
local Optimizer = require("ast_optimizer")
local CodeGen = require("codegen")
local Repl = require("repl")

local equinox = {}
local optimizer = Optimizer:new()
local compiler = Compiler:new(optimizer, CodeGen:new())
local repl = Repl:new(compiler, optimizer)

local lua_require = require

function require(module_name)
  if module_name:lower():match("%.eqx$") then
    return equinox.eval_file(module_name, false)
  else
    return lua_require(module_name)
  end
end

local lib = [[
alias: append #( table.insert 2 0 )
alias: insert #( table.insert 3 0 )
alias: remove #( table.remove 2 0 )
alias: >str #( tostring 1 1 )
alias: >num #( tonumber 1 1 )
alias: need #( require 1 1 )
alias: type #( type 1 1 )
alias: max  #( math.max 2 1 )
alias: min  #( math.min 2 1 )
alias: pow  #( math.pow 2 1 )
alias: # size
alias: emit #( string.char 1 1 ) #( io.write 1 0 )

: assert-true #( assert 1 0 ) ;
: assert-false not assert-true ;
: =assert = assert-true ;

: [ depth >a ;
: ]
  []
  depth a> - 1 - 0
  do
    dup >a
    1 rot insert ( tbl idx value )
    a>
  loop ;

: { depth >a ;
: }
    {}
    depth a> - 1 -
    dup 2 % 0 != if
      "Table needs even number of items" #( error 1 )
    then
    2 / 0 do
      dup >a -rot ! a>
    loop ;
]]

local function version()
  if __VERSION__ then
    return __VERSION__
  else
    version = require("version/version")
    version.load()
    return version.current
  end
end

local function start_repl()
  repl:welcome(version())
  repl:start()
end

function equinox.eval_files(files, log_result)
  local result = nil
  for i, filename in ipairs(files) do
    if log_result then
      print("Loading " .. filename)
    end
    result = equinox.eval_file(filename, log_result)
  end
  return result
end

function equinox.init()
  compiler:eval_text(lib)
end

function equinox.main()
  if #arg < 1 then
    equinox.init()
    start_repl()
  else
    local log_result, repl = false, false
    local files = {}
    for i, param in ipairs(arg) do
      if param == "-d" then
        log_result = true
      elseif param == "-o0" then
        optimizer:enable(false)
      elseif param == "-o1" then
        optimizer:enable(true)
      elseif param == "-od" then
        optimizer:enable_logging(true)
      elseif param == "-repl" then
        repl = true
      else
        table.insert(files, param)
      end
    end
    equinox.init()
    equinox.eval_files(files, log_result)
    if repl then start_repl() end
  end
end

function equinox.eval_text(str, log_result)
  return compiler:eval_text(str, log_result)
end

function equinox.eval_file(str, log_result)
  return compiler:eval_file(str, log_result)
end

equinox.traceback = function(err)
  return compiler:traceback(err)
end

if arg and arg[0] and
  (arg[0]:match("equinox.lua$") or
   arg[0]:match("equinox_bundle.lua$")) then
  equinox.main(arg)
end

return equinox
