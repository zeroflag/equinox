do
local _ENV = _ENV
package.preload[ "aux" ] = function( ... ) local arg = _G.arg;
local Stack = require("stack_def")
local aux = Stack.new("aux-stack")

return aux
end
end

do
local _ENV = _ENV
package.preload[ "compiler" ] = function( ... ) local arg = _G.arg;
-- TODO:
-- user defined control structues
-- var/local scopes
-- case
-- begin while repeat
-- for
-- hyperstatic glob
-- benchmarks
-- fix Lua's accidental global
-- tab auto complete repl
-- alias lua table operationokre
-- ncurses REPL with stack (main/aux) visualization
-- : p.x 123 ;
local stack = require("stack")
local macros = require("macros")
local ops = require("ops")
local Stack = require("stack_def")
local dict = require("dict")
local Input = require("input")
local Output = require("output")
local interop = require("interop")
local err  = require("err")

-- TODO XXX
_G["macros"] = macros

local compiler = { input = nil, output = nil }

function compiler.word(self)
  return self.input:parse()
end

function compiler.next(self)
  return self.input:next()
end

function compiler.word_list(self)
  return dict.word_list()
end

function compiler.emit_lit(self, token)
  self:emit_line("ops.lit(" .. token .. ")")
end

function compiler.emit_symbol(self, token)
  self:emit_lit('"' .. token:sub(2) .. '"')
end

function compiler.emit_word(self, word)
  if word.callable then
    self:emit_line(word.name .. "()")
  else
    self:emit_line("ops.lit(" .. word.name .. ")")
  end
end

function compiler.emit_lua_call(self, name, arity, vararg, void)
  if vararg then
    err.abort(name .. " has variable/unknown number of arguments. " ..
          "Use " .. name .. "/n" .. " to specify arity. " ..
          "For example " .. name .. "/1")
  end
  if arity > 0 then
    self:emit("local ")
    for i = 1, arity do
      self:emit("__p" .. (arity - i +1))
      if i < arity then
        self:emit(",")
      else
        self:emit("=")
      end
    end
    for i = 1, arity do
      self:emit("stack:pop()")
      if i < arity then
        self:emit(",")
      end
    end
  end
  self:emit_line("")
  if void then
    self:emit(name .. "(")
  else
    self:emit("stack:push(" .. name .. "(")
  end
  for i = 1, arity do
    self:emit("__p" .. i)
    if i < arity then
      self:emit(",")
    end
  end
  if void then
    self:emit_line(")")
  else
    self:emit_line("))")
  end
end

function compiler.compile_token(self, token, kind)
  if kind == "string" then
    self:emit_lit(token)
  elseif kind == "symbol" then
    self:emit_symbol(token)
  else
    local word = dict.find(token)
    if word then
      self:emit_word(word)
    else
      local num = tonumber(token)
      if num then
        self:emit_lit(num)
      else
        local res = interop.resolve_lua_func_with_arity(token)
        if res then
          self:emit_lua_call(res.name, res.arity, res.vararg, res.void)
        else
          err.abort("Word not found: '" .. token .. "'")
        end
      end
    end
  end
end

function compiler.defword(self, alias, name, immediate)
  dict.defword(alias, name, immediate)
end

function compiler.defvar(self, alias, name)
  dict.defvar(alias, name)
end

function compiler.exec(self, word)
  local mod, fun = dict.find(word).name:match("^(.-)%.(.+)$")
  _G[mod][fun](self)
end

function compiler.init(self, text)
  self.input = Input.new(text)
  self.output = Output.new()
  self:emit_line("local ops = require(\"ops\")")
  self:emit_line("local stack = require(\"stack\")")
  self:emit_line("local aux = require(\"aux\")")
  dict.defvar("true", "true")
  dict.defvar("false", "false")
  dict.defvar("nil", "NIL")
end

function compiler.compile(self, text)
  self:init(text)
  local token, kind = self:word()
  while token ~= "" do
    if kind == "word"
      and dict.find(token)
      and dict.find(token).imm
    then
      self:exec(token)
    else
      self:compile_token(token, kind)
    end
    token, kind = self:word()
  end
  --print(self.output:text())
  return self.output
end

function compiler.eval(self, text)
  local out = self:compile(text)
  out:load()
  return stack
end

function compiler.eval_file(self, path)
  local file = io.open(path, "r")
  if not file then
    err.abort("Could not open file: " .. path)
  end
  local content = file:read("*a")
  file:close()
  return self:eval(content)
end

function compiler.emit_line(self, token)
  self:emit(token)
  self.output:cr()
end

function compiler.emit(self, token)
  self.output:append(token)
end

return compiler
end
end

do
local _ENV = _ENV
package.preload[ "dict" ] = function( ... ) local arg = _G.arg;
local dict  = { words = {} }

-- TODO kuloncs kulcs alatt legyen a dict
-- mert igy a wordlistben latszik

function dict.defword(alias, name, immediate)
  dict["words"][alias] = { ["name"] = name, imm = immediate, callable = true }
end

function dict.defvar(alias, name)
  dict["words"][alias] = { ["name"] = name, callable = false }
end

function dict.find(name)
  return dict["words"][name]
end

function dict.word_list()
  local words = {}
  for name, val in pairs(dict["words"]) do
    table.insert(words, name)
  end
  return words
end

dict.defword("+", "ops.add", false)
dict.defword("-", "ops.sub", false)
dict.defword("*", "ops.mul", false)
dict.defword("/", "ops.div", false)
dict.defword("%", "ops.mod", false)
dict.defword(".", "ops.dot", false)
dict.defword("=", "ops.eq", false)
dict.defword("!=", "ops.neq", false)
dict.defword("<", "ops.lt", false)
dict.defword("<=", "ops.lte", false)
dict.defword(">", "ops.gt", false)
dict.defword(">=", "ops.gte", false)
dict.defword("swap", "ops.swap", false)
dict.defword("over", "ops.over", false)
dict.defword("rot", "ops.rot", false)
dict.defword("drop", "ops.drop", false)
dict.defword("dup", "ops.dup", false)
dict.defword("depth", "ops.depth", false)
dict.defword("adepth", "ops.adepth", false)
dict.defword("not", "ops._not", false)
dict.defword("and", "ops._and", false)
dict.defword("or", "ops._or", false)
dict.defword("..", "ops.concat", false)
dict.defword(">a", "ops.to_aux", false)
dict.defword("a>", "ops.from_aux", false)
dict.defword("assert", "ops.assert", false)
dict.defword("shields-up", "ops.shields_up", false)
dict.defword("shields-down", "ops.shields_down", false)
dict.defword("<table>", "ops.new_table", false)
dict.defword("size", "ops.table_size", false)
dict.defword("at", "ops.table_at", false)
dict.defword("put", "ops.table_put", false)
dict.defword("words", "macros.words", true)
dict.defword("if", "macros._if", true)
dict.defword("then", "macros._then", true)
dict.defword("else", "macros._else", true)
dict.defword("begin", "macros._begin", true)
dict.defword("until", "macros._until", true)
dict.defword("do", "macros._do", true)
dict.defword("loop", "macros._loop", true)
dict.defword("i", "macros._i", true)
dict.defword("j", "macros._j", true)
dict.defword("->", "macros.assignment", true)
dict.defword("var", "macros.var", true)
dict.defword("(", "macros.comment", true)
dict.defword("\\", "macros.single_line_comment", true)
dict.defword(":", "macros.colon", true)
dict.defword(";", "macros._end", true)

return dict
end
end

do
local _ENV = _ENV
package.preload[ "err" ] = function( ... ) local arg = _G.arg;
local err = {}

function err.abort(str)
  error("\27[31mRed Alert:\27[0m " .. str)
end

function err.warn(str)
  print("\27[33mYellow Alert:\27[0m " .. str)
end

return err
end
end

do
local _ENV = _ENV
package.preload[ "input" ] = function( ... ) local arg = _G.arg;
local Input = {}

function Input.new(source)
  local obj = {index = 1, source = source}
  setmetatable(obj, {__index = Input})
  return obj
end

function Input.parse(self)
  local token = ""
  local begin_str = false
  local stop = false
  local kind = "word"
  while not self:ended() and not stop do
    local chr = self:next()
    if self:is_quote(chr) then
      if begin_str then
        stop = true
      else
        kind = "string"
        begin_str = true
      end
    end
    if self:is_whitespace(chr) and not begin_str then
      if #token > 0 then
        stop = true
      end
    else
      token = token .. chr
    end
  end
  if token:match("^:.+") then
    kind = "symbol"
  end
  return token, kind
end

function Input.is_quote(self, chr)
  return chr:match('"')
end

function Input.is_whitespace(self, chr)
  return chr:match("%s")
end

function Input.next(self)
  local chr = self.source:sub(self.index, self.index)
  self.index = self.index + 1
  return chr
end

function Input.ended(self)
  return self.index > #self.source
end

return Input
end
end

do
local _ENV = _ENV
package.preload[ "interop" ] = function( ... ) local arg = _G.arg;
local interop = {}

function interop.resolve_lua_func(name)
  local func = _G
  for part in name:gmatch("[^%.]+") do
    func = func[part]
    if func == nil then return nil end
  end
  if type(func) == "function" then
    return func
  else
    return nil
  end
end

function interop.parse_signature(signature)
  local name, arity = string.match(signature, "([^%/]+)(%/%d+)")
  if name and arity then
    return name, tonumber(arity:sub(2)), false
  end
  local name, arity = string.match(signature, "([^%/]+)(%!%d+)")
  if name and arity then
    return name, tonumber(arity:sub(2)), true
  end
  return signature
end

function interop.resolve_lua_func_with_arity(signature)
  local name, arity, void = interop.parse_signature(signature)
  local func = interop.resolve_lua_func(name)
  local vararg = false
  if not func then return nil end
  if not arity then
    local info = debug.getinfo(func, "u") -- Doesn't work with C funcs or older than Lua5.2
    arity, vararg = info.nparams, info.isvararg
    if not arity then vararg = true end
  end
  return { name = name, arity = arity, vararg = vararg, void = void }
end

return interop
end
end

do
local _ENV = _ENV
package.preload[ "macros" ] = function( ... ) local arg = _G.arg;
local stack = require("stack")
local aux = require("aux")
local interop = require("interop")
local macros = {}

local id_counter = 1

function gen_id(prefix)
  id_counter = id_counter + 1
  return prefix .. id_counter
end

function sanitize(str)
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
    :gsub(":", "_cm_")
    :gsub("%{", "_c1_")
    :gsub("%}", "_c2_")
    :gsub("%[", "_b1_")
    :gsub("%]", "_b2_")
    :gsub("%(", "_p1_")
    :gsub("%(", "_p2_")
  if str:match("^%d+") then
    str = "_" .. str
  end
  return str
end

function macros.colon(compiler)
  local alias, arity, void = interop.parse_signature(compiler:word())
  local name = sanitize(alias)
  compiler:defword(alias, name, false)
  if not arity or arity == 0 then
    compiler:emit_line("function " .. name .. "()")
  else
    compiler:emit("function " .. name .. "(")
    for i = 1, arity do
      compiler:emit("__a" .. i)
      if i < arity then
        compiler:emit(",")
      else
        compiler:emit_line(")")
      end
    end
    for i = 1, arity do
      compiler:emit_line("stack:push(__a" .. i ..")")
    end
  end
end

function macros.comment(compiler)
  repeat until ")" == compiler:next()
end

function macros.single_line_comment(compiler)
  repeat until "\n" == compiler:next()
end

function macros.var(compiler)
  local alias = compiler:word()
  local name = "v_" .. alias
  compiler:defvar(alias, name)
  compiler:emit_line("local " .. name)
end

function macros.assignment(compiler)
  local alias = compiler:word()
  local name = "v_" .. alias
  compiler:emit_line(name .. " = stack:pop()")
end

function macros._if(compiler)
  compiler:emit_line("if stack:pop() then")
end

function macros._else(compiler)
  compiler:emit_line("else")
end

function macros._then(compiler)
  compiler:emit_line("end")
end

function macros._begin(compiler)
  compiler:emit_line("repeat")
end

function macros._until(compiler)
  compiler:emit_line("until(stack:pop())")
end

-- TODO this might overwrite user defined i/j ?
function macros._i(compiler)
  compiler:emit_line("stack:push(aux:tos())")
end

-- TODO this might overwrite user defined i/j ?
function macros._j(compiler)
  compiler:emit_line("stack:push(aux:tos2())")
end

function macros._do(compiler)
  local var = gen_id("loop_var")
  compiler:emit_line("for ".. var .."=stack:pop(), stack:pop() -1 do")
  compiler:emit_line("aux:push(".. var ..")")
end

function macros._loop(compiler)
  compiler:emit_line("aux:pop()") -- unloop i/j
  compiler:emit_line("end")
end

function macros._end(compiler)
  compiler:emit_line("end")
end

function macros.words(compiler)
  for i, each in ipairs(compiler.word_list()) do
    io.write(each .. " ")
  end
  print()
end

return macros
end
end

do
local _ENV = _ENV
package.preload[ "ops" ] = function( ... ) local arg = _G.arg;
local Stack = require("stack_def")
local stack = require("stack")
local aux = require("aux")
local ops = {}

function ops.dup()
  stack:push(stack:tos())
end

function ops.add()
  stack:push(stack:pop() + stack:pop())
end

function ops.mul()
  stack:push(stack:pop() * stack:pop())
end

function ops.div()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(b / a)
end

function ops.mod()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(b % a)
end

function ops.sub()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(b - a)
end

function ops.depth()
  stack:push(stack:depth())
end

function ops.adepth()
  stack:push(aux:depth())
end

function ops.swap()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(a)
  stack:push(b)
end

function ops.over()
  stack:push(stack:tos2())
end

function ops.rot()
  local c = stack:pop()
  local b = stack:pop()
  local a = stack:pop()
  stack:push(b)
  stack:push(c)
  stack:push(a)
end

function ops.drop()
  stack:pop()
end

function ops.eq()
  stack:push(stack:pop() == stack:pop())
end

function ops.neq()
  stack:push(stack:pop() ~= stack:pop())
end

function ops.lt()
  stack:push(stack:pop() > stack:pop())
end

function ops.lte()
  stack:push(stack:pop() >= stack:pop())
end

function ops.gt()
  stack:push(stack:pop() < stack:pop())
end

function ops.gte()
  stack:push(stack:pop() <= stack:pop())
end

function ops._not()
  stack:push(not stack:pop())
end

function ops._and()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(a and b)
end

function ops._or()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(a or b)
end

function ops.concat()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(b .. a)
end

function ops.dot()
  io.write(tostring(stack:pop()))
  io.write(" ")
end

function ops.lit(literal)
  stack:push(literal)
end

function ops.to_aux()
  aux:push(stack:pop())
end

function ops.from_aux()
  stack:push(aux:pop())
end

function ops.new_table()
  stack:push({})
end

function ops.table_size()
  stack:push(#stack:pop())
end

function ops.table_at()
  local n = stack:pop()
  local t = stack:pop()
  stack:push(t[n])
end

function ops:table_put()
  local value = stack:pop()
  local key = stack:pop()
  local tbl = stack:pop()
  tbl[key] = value
end

function ops:shields_up()
  Stack.safety(true)
end

function ops:shields_down()
  Stack.safety(false)
end

return ops
end
end

do
local _ENV = _ENV
package.preload[ "output" ] = function( ... ) local arg = _G.arg;
local Output = {}

function Output.new()
  local obj = {buffer = {}}
  setmetatable(obj, {__index = Output})
  return obj
end

function Output.append(self, str)
  table.insert(self.buffer, str)
end

function Output.cr(self)
  self:append("\n")
end

function Output.text(self)
  return table.concat(self.buffer)
end

function Output.load(self)
  local text = self:text()
  if loadstring then
    loadstring(text)()
  else -- Since Lua 5.2, loadstring has been replaced by load.
    load(text)()
  end
end

return Output
end
end

do
local _ENV = _ENV
package.preload[ "repl" ] = function( ... ) local arg = _G.arg;
local compiler = require("compiler")
local stack = require("stack")

local repl = {}

function repl.welcome()
  print("Welcome to the Delta Quadrant on Equinox (" .. _VERSION .. ")")
  print("Engage warp speed and may your stack never overflow.")

  print([[
 ___________________          _-_
 \__(==========/_=_/ ____.---'---`---.____
             \_ \    \----._________.----/
               \ \   /  /    `-_-'
           __,--`.`-'..'-_
         /____          ||
               `--.____,-'
  ]])
  print("Type words to see wordlist or bye to exit.")
end

function repl.start()
  while true do
    io.write("# ")
    local input = io.read()
    if input == "bye" then
      break
    end
    local status, result = pcall(
      function()
        return compiler:eval(input)
      end)
    if status then
      if stack:depth() > 0 then
        print("ok (" .. stack:depth() .. ")")
      else
        print("ok")
      end
    else
      print(result)
    end
  end
end

return repl
end
end

do
local _ENV = _ENV
package.preload[ "stack" ] = function( ... ) local arg = _G.arg;
local Stack = require("stack_def")
local stack = Stack.new("data-stack")

return stack
end
end

do
local _ENV = _ENV
package.preload[ "stack_def" ] = function( ... ) local arg = _G.arg;
local err = require("err")

local Stack = {}
local NIL = "__NIL__"

function Stack.new(name)
  local obj = {stack = {}, name = name}
  setmetatable(obj, {__index = Stack})
  return obj
end

function Stack.push(self, e)
  table.insert(self.stack, e ~= nil and e or NIL)
end

function Stack.pop_safe(self)
  local item = table.remove(self.stack)
  if item == nil then
    err.abort("Stack underflow: " .. self.name)
  end
  return item ~= NIL and item or nil
end

function Stack.pop_unsafe(self)
  local item = table.remove(self.stack)
  return item ~= NIL and item or nil
end

function Stack.tos(self)
  return self.stack[#self.stack]
end

function Stack.tos2(self)
  return self.stack[#self.stack - 1]
end

function Stack.depth(self)
  return #self.stack
end

function Stack.safety(safe)
  if safe then
    Stack.pop = Stack.pop_safe
  else
    Stack.pop = Stack.pop_unsafe
  end
end

Stack.safety(true)

return Stack
end
end

compiler = require("compiler")
repl = require("repl")

local equinox = {}

function equinox.main()
  compiler:eval_file("lib.eqx")
  if #arg < 1 then
    repl.welcome()
    repl.start()
  else
    local filename = arg[1]
    print("Loading " .. filename)
    compiler:eval_file(filename)
  end
end

function equinox.eval(str)
  return compiler:eval(str)
end

function equinox.eval_file(str)
  return compiler:eval_file(str)
end

if arg and arg[0] == "equinox.lua" then
  equinox.main(arg)
end

return equinox
