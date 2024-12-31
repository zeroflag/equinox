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
-- for
-- hyperstatic glob
-- benchmarks
-- Stack as Macro
-- fix Lua's accidental global
-- tab auto complete repl
-- repl command load file
-- line numbers + errors
-- table.prop syntax (check)

local stack = require("stack")
local macros = require("macros")
local Stack = require("stack_def")
local dict = require("dict")
local Input = require("input")
local Output = require("output")
local interop = require("interop")
local err  = require("err")

-- TODO XXX
_G["macros"] = macros

local compiler = { input = nil, output = nil, code_start = 1 }

function compiler.word(self)
  return self.input:parse()
end

function compiler.next(self)
  return self.input:next()
end

function compiler.word_list(self)
  return dict.word_list()
end

function compiler.line_number(self)
  return self.output:size()
end

function compiler.update_line(self, line, line_number)
  return self.output:update_line(line, line_number)
end

function compiler.alias(self, lua_name, forth_alias)
  return dict.def_lua_alias(lua_name, forth_alias)
end

function compiler.emit_lit(self, token)
  self:emit_line("stack:push(" .. token .. ")")
end

function compiler.emit_symbol(self, token)
  self:emit_lit('"' .. token:sub(2) .. '"')
end

function compiler.emit_word(self, word)
  if word.callable then
    self:emit_line(word.lua_name .. "()")
  else
    self:emit_line("stack:push(" .. word.lua_name .. ")")
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
    self:emit_line("")
  end
  if void then
    self:emit(name .. "(")
  else
    self:emit("stack:push_many(" .. name .. "(")
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

function compiler.emit_lua_prop_lookup(self, token)
  self:emit_line("stack:push(" .. token .. ")")
end

function compiler.compile_token(self, token, kind)
  if kind == "string" then
    self:emit_lit(token)
  elseif kind == "symbol" then
    self:emit_symbol(token)
  else
    local word = dict.find(token)
    if word then
      if word.is_lua_alias then
        -- Known lua alias
        local res = interop.resolve_lua_func_with_arity(word.lua_name)
        self:emit_lua_call(res.name, res.arity, res.vararg, res.void)
      else
        -- Forth word
        self:emit_word(word)
      end
    else
      local num = tonumber(token)
      if num then
        self:emit_lit(num)
      else
        -- Unknown lua call
        local res = interop.resolve_lua_method_call(token)
        if res then
          self:emit_lua_call(res.name, res.arity, res.vararg, res.void)
        else
          local res = interop.resolve_lua_func_with_arity(token)
          if res then
            self:emit_lua_call(res.name, res.arity, res.vararg, res.void)
          elseif interop.is_lua_prop_lookup(token) then
            -- TODO check lhs(s) is a defined var or in _G
            -- Table lookup
            self:emit_lua_prop_lookup(token)
          else
            err.abort("Word not found: '" .. token .. "'")
          end
        end
      end
    end
  end
end

function compiler.def_word(self, alias, name, immediate)
  dict.def_word(alias, name, immediate)
end

function compiler.def_var(self, alias, name)
  dict.def_var(alias, name)
end

function compiler.exec(self, word)
  local mod, fun = dict.find(word).lua_name:match("^(.-)%.(.+)$")
  _G[mod][fun](self)
end

function compiler.init(self, text)
  self.input = Input.new(text)
  self.output = Output.new()
  self:emit_line("local stack = require(\"stack\")")
  self:emit_line("local aux = require(\"aux\")")
  self.code_start = self.output:size() + 1
  dict.def_var("true", "true")
  dict.def_var("false", "false")
  dict.def_var("nil", "NIL")
end

function compiler.compile(self, text)
  self:init(text)
  local token, kind = self:word()
  while token ~= "" do
    local word_def = dict.find(token)
    if kind == "word"
      and word_def
      and word_def.immediate
    then
      self:exec(token)
    else
      self:compile_token(token, kind)
    end
    token, kind = self:word()
  end
  return self.output
end

function compiler.eval(self, text, log_result)
  self:compile_and_load(text, log_result)()
  return stack
end

function compiler.compile_and_load(self, text, log_result)
  local out = self:compile(text)
  if log_result then
    print(self.output:text(self.code_start))
  end
  return out:load()
end

function compiler.eval_file(self, path, log_result)
  local file = io.open(path, "r")
  if not file then
    err.abort("Could not open file: " .. path)
  end
  local content = file:read("*a")
  file:close()
  return self:eval(content, log_result)
end

function compiler.emit_line(self, token)
  self:emit(token)
  self.output:new_line()
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
local words = {}
local dict  = { words = words }

function entry(forth_name, lua_name, immediate, callable, is_lua_alias)
  return {
    forth_name = forth_name,
    lua_name = lua_name,
    immediate = immediate,
    callable = callable,
    is_lua_alias = is_lua_alias
  }
end

function dict.def_word(forth_name, lua_name, immediate)
  table.insert(words, entry(forth_name, lua_name, immediate, true, false))
end

function dict.def_macro(forth_name, lua_name)
  dict.def_word(forth_name, lua_name, true)
end

function dict.def_lua_alias(lua_name, forth_name)
  table.insert(words, entry(forth_name, lua_name, immediate, false, true))
end

function dict.def_var(forth_name, lua_name)
  table.insert(words, entry(forth_name, lua_name, immediate, false, false))
end

function dict.find(forth_name)
  for i = #words, 1, -1 do
    local each = words[i]
    if each.forth_name == forth_name then
      return each
    end
  end
  return nil
end

function dict.word_list()
  local result = {}
  for i, each in ipairs(words) do
    table.insert(result, each.forth_name)
  end
  return result
end

dict.def_macro("+", "macros.add")
dict.def_macro("-", "macros.sub")
dict.def_macro("*", "macros.mul")
dict.def_macro("/", "macros.div")
dict.def_macro("%", "macros.mod")
dict.def_macro(".", "macros.dot")
dict.def_macro("cr", "macros.cr")
dict.def_macro("=", "macros.eq")
dict.def_macro("!=", "macros.neq")
dict.def_macro("<", "macros.lt")
dict.def_macro("<=", "macros.lte")
dict.def_macro(">", "macros.gt")
dict.def_macro(">=", "macros.gte")
dict.def_macro("swap", "macros.swap")
dict.def_macro("over", "macros.over")
dict.def_macro("rot", "macros.rot")
dict.def_macro("drop", "macros.drop")
dict.def_macro("dup", "macros.dup")
dict.def_macro("depth", "macros.depth")
dict.def_macro("adepth", "macros.adepth")
dict.def_macro("not", "macros._not")
dict.def_macro("and", "macros._and")
dict.def_macro("or", "macros._or")
dict.def_macro("..", "macros.concat")
dict.def_macro(">a", "macros.to_aux")
dict.def_macro("a>", "macros.from_aux")
dict.def_macro("<table>", "macros.new_table")
dict.def_macro("size", "macros.table_size")
dict.def_macro("at", "macros.table_at")
dict.def_macro("put", "macros.table_put")
dict.def_macro("words", "macros.words")
dict.def_macro("exit", "macros._exit")
dict.def_macro("if", "macros._if")
dict.def_macro("then", "macros._then")
dict.def_macro("else", "macros._else")
dict.def_macro("begin", "macros._begin")
dict.def_macro("until", "macros._until")
dict.def_macro("while", "macros._while")
dict.def_macro("repeat", "macros._repeat")
dict.def_macro("again", "macros._repeat") -- same as repeat
dict.def_macro("case", "macros._case")
dict.def_macro("of", "macros._of")
dict.def_macro("endof", "macros._endof")
dict.def_macro("endcase", "macros._endcase")
dict.def_macro("do", "macros._do")
dict.def_macro("loop", "macros._loop")
dict.def_macro("unloop", "macros.unloop")
dict.def_macro("i", "macros._i")
dict.def_macro("j", "macros._j")
dict.def_macro("ipairs:", "macros.for_ipairs")
dict.def_macro("pairs:", "macros.for_pairs")
dict.def_macro("->", "macros.assignment")
dict.def_macro("var", "macros.var")
dict.def_macro("(", "macros.comment")
dict.def_macro("\\", "macros.single_line_comment")
dict.def_macro("lua-alias:", "macros.def_lua_alias")
dict.def_macro(":", "macros.colon")
dict.def_macro(";", "macros._end")
dict.def_macro("end", "macros._end")

return dict
end
end

do
local _ENV = _ENV
package.preload[ "err" ] = function( ... ) local arg = _G.arg;
local err = {}

function err.abort(str)
  error("Red Alert: " .. str)
end

function err.warn(str)
  print("Yellow Alert: " .. str)
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
        self.index = self.index -1 -- don't consume next WS as it breaks single line comment
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
  return signature, 0, false
end

function interop.resolve_lua_func_with_arity(signature)
  local name, arity, void = interop.parse_signature(signature)
  local func = interop.resolve_lua_func(name)
  local vararg = false
  if not func then
    return nil
  else
    return {name = name, arity = arity, vararg = vararg, void = void}
  end
end

function interop.resolve_lua_method_call(signature)
  local name, arity, void = interop.parse_signature(signature)
  local obj, method = string.match(name, "(.+):(.+)")
  if obj and method then
    return {name = name, arity = arity, void = void, vararg = false}
  else
    return obj
  end
end

function interop.is_lua_prop_lookup(token)
  return string.match(token, ".+%..+")
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

function macros.add(compiler)
  compiler:emit_line("stack:push(stack:pop() + stack:pop())")
end

function macros.mul(compiler)
  compiler:emit_line("stack:push(stack:pop() * stack:pop())")
end

function macros.sub(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_b - _a)]])
end

function macros.div(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_b / _a)]])
end

function macros.mod(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_b % _a)]])
end

function macros.eq(compiler)
  compiler:emit_line("stack:push(stack:pop() == stack:pop())")
end

function macros.neq(compiler)
  compiler:emit_line("stack:push(stack:pop() ~= stack:pop())")
end

function macros.lt(compiler)
  compiler:emit_line("stack:push(stack:pop() > stack:pop())")
end

function macros.lte(compiler)
  compiler:emit_line("stack:push(stack:pop() >= stack:pop())")
end

function macros.gt(compiler)
  compiler:emit_line("stack:push(stack:pop() < stack:pop())")
end

function macros.gte(compiler)
  compiler:emit_line("stack:push(stack:pop() <= stack:pop())")
end

function macros._not(compiler)
  compiler:emit_line("stack:push(not stack:pop())")
end

function macros._and(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_a and _b)]])
end

function macros._or(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_a or _b)]])
end

function macros.concat(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_b .. _a)]])
end

function macros.new_table(compiler)
  compiler:emit_line("stack:push({})")
end

function macros.table_size(compiler)
  compiler:emit_line("stack:push(#stack:pop())")
end

function macros.table_at(compiler)
  compiler:emit_line([[
local _n = stack:pop()
local _t = stack:pop()
stack:push(_t[_n])]])
end

function macros.table_put(compiler)
  compiler:emit_line([[
local _val = stack:pop()
local _key = stack:pop()
local _tbl = stack:pop()
_tbl[_key] = _val]])
end

function macros.depth(compiler)
  compiler:emit_line("stack:push(stack:depth())")
end

function macros.adepth(compiler)
  compiler:emit_line("stack:push(aux:depth())")
end

function macros.dup(compiler)
  compiler:emit_line("stack:push(stack:tos())")
end

function macros.drop(compiler)
  compiler:emit_line("stack:pop()")
end

function macros.over(compiler)
  compiler:emit_line("stack:push(stack:tos2())")
end

function macros.rot(compiler)
  compiler:emit_line([[
local _c = stack:pop()
local _b = stack:pop()
local _a = stack:pop()
stack:push(_b)
stack:push(_c)
stack:push(_a)]])
end

function macros.swap(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_a)
stack:push(_b)]])
end

function macros.to_aux(compiler)
  compiler:emit_line("aux:push(stack:pop())")
end

function macros.from_aux(compiler)
  compiler:emit_line("stack:push(aux:pop())")
end

function macros.dot(compiler)
  compiler:emit_line([[
io.write(tostring(stack:pop()))
io.write(" ")]])
end

function macros.cr(compiler)
  compiler:emit_line("print()")
end

function macros.def_lua_alias(compiler)
  local lua_name = compiler:word()
  forth_alias = compiler:word()
  compiler:alias(lua_name, forth_alias)
end

function macros.colon(compiler)
  local forth_name, arity, void = interop.parse_signature(compiler:word())
  local lua_name = sanitize(forth_name)
  compiler:def_word(forth_name, lua_name, false)
  if not arity or arity == 0 then
    compiler:emit_line("function " .. lua_name .. "()")
  else
    compiler:emit("function " .. lua_name .. "(")
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
  local name = compiler:word()
  compiler:def_var(name, name)
  compiler:emit_line("local " .. name)
end

function macros.assignment(compiler)
  compiler:emit_line(compiler:word() .. " = stack:pop()")
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
  local line_number = compiler:line_number()
  compiler:emit_line("-- placeholder begin")
  stack:push(line_number)
end

function macros._until(compiler)
  local line_number = stack:pop()
  compiler:update_line("repeat", line_number)
  compiler:emit_line("until(stack:pop())", line_number)
end

function macros._while(compiler)
  compiler:emit_line("if not stack:pop() then break end")
end

function macros._repeat(compiler)
  local line_number = stack:pop()
  compiler:update_line("while(true) do", line_number)
  compiler:emit_line("end")
end

function macros._case(compiler)
  -- simulate goto with break, in pre lua5.2 since GOTO was not yet supported
  compiler:emit_line("repeat")
end

function macros._of(compiler)
  compiler:emit_line("stack:push(stack:tos2())") -- OVER
  compiler:emit_line("if stack:pop() == stack:pop() then")
  compiler:emit_line("stack:pop()") -- DROP selector value
end

function macros._endof(compiler)
  compiler:emit_line("break end") -- GOTO endcase
end

function macros._endcase(compiler)
  compiler:emit_line("until true")
end

function macros._exit(compiler)
  compiler:emit_line("do return end")
end

-- TODO this might overwrite user defined i/j ?
function macros._i(compiler)
  compiler:emit_line("stack:push(aux:tos())")
end

-- TODO this might overwrite user defined i/j ?
function macros._j(compiler)
  compiler:emit_line("stack:push(aux:tos2())")
end

function macros.unloop(compiler)
  compiler:emit_line("aux:pop()")
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

function macros.for_ipairs(compiler)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  -- TODO should be removed or we should maintain proper scope
  compiler:def_var(var_name1, var_name1)
  compiler:def_var(var_name2, var_name2)
  compiler:emit_line(string.format(
    "for %s,%s in ipairs(stack:pop()) do", var_name1, var_name2))
end

function macros.for_pairs(compiler)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  -- TODO should be removed or we should maintain proper scope
  compiler:def_var(var_name1, var_name1)
  compiler:def_var(var_name2, var_name2)
  compiler:emit_line(string.format(
    "for %s,%s in pairs(stack:pop()) do", var_name1, var_name2))
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
package.preload[ "output" ] = function( ... ) local arg = _G.arg;
local Output = {}

function Output.new()
  local obj = {lines = {""}}
  setmetatable(obj, {__index = Output})
  return obj
end

function Output.append(self, str)
  self.lines[self:size()] = self.lines[self:size()] .. str
end

function Output.update_line(self, str, line_number)
  self.lines[line_number] = str
end

function Output.new_line(self)
  table.insert(self.lines, "")
end

function Output.size(self)
  return #self.lines
end

function Output.text(self, from)
  return table.concat(self.lines, "\n", from)
end

function Output.load(self)
  local text = self:text()
  if loadstring then
    return loadstring(text)
  else -- Since Lua 5.2, loadstring has been replaced by load.
    return load(text)
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

local SINGLE_LINE = 1
local MULTI_LINE = 2

local repl = { mode = SINGLE_LINE, input = "", log_result = false }

function repl.welcome(version)
  print("Welcome to the Delta Quadrant on Equinox (" .. _VERSION .. ")")
  print("Engage warp speed and may your stack never overflow.")
  print("\27[1;96m")
  print(string.format([[
 ___________________          _-_
 \__(==========/_=_/ ____.---'---`---.____
             \_ \    \----._________.----/
               \ \   /  /    `-_-'
          ___,--`.`-'..'-_
         /____          ||
               `--.____,-'   v%s
]], version))
  print("\27[0m")
  print("Type 'words' for wordlist, 'bye' to exit or 'help'.")
end

function show_help()
  print([[
- log-on: turn on logging
- log-off: turn off logging
- bye: exit repl
- help: show this help
  ]])
end

function repl.prompt()
  if repl.mode == SINGLE_LINE then
    return "#"
  else
    return "..."
  end
end

function repl.show_prompt()
  io.write(string.format("\27[1;95m%s \27[0m", repl.prompt()))
end

function repl.read()
  if repl.mode == SINGLE_LINE then
    repl.input = io.read()
  else
    repl.input = repl.input .. "\n" .. io.read()
  end
end

function repl.process_commands()
  if repl.input == "bye" then
    os.exit(0)
  end
  if repl.input == "help" then
    show_help()
    return true
  end
  if repl.input == "log-on" then
    repl.log_result = true
    print("Log turned on")
    return true
  end
  if repl.input == "log-off" then
    repl.log_result = false
    print("Log turned off")
    return true
  end
  return false
end

function repl.print_err(result)
  print("\27[91m" ..result .. "\27[0m")
end

function repl.print_ok()
  if stack:depth() > 0 then
    print("\27[92m" .. "OK(".. stack:depth()  .. ")" .. "\27[0m")
  else
    print("\27[92mOK\27[0m")
  end
end

function repl.start()
  local prompt = "#"
  while true do
    repl.show_prompt()
    repl.read()
    if not repl.process_commands() then
      local success, result = pcall(function ()
          return compiler:compile_and_load(repl.input, repl.log_result)
      end)
      if not success then
        repl.print_err(result)
      elseif not result then
        repl.mode = MULTI_LINE
      else
        repl.mode = SINGLE_LINE
        local success, result = pcall(function() result() end)
        if success then
          repl.print_ok()
        else
          repl.print_err(result)
        end
      end
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

function Stack.push_many(self, ...)
  for i, item in ipairs({...}) do
    self:push(item)
  end
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
  version = require("version/version")
  version.load()
  compiler:eval_file("lib.eqx")
  if #arg < 1 then
    repl.welcome(version.current)
    repl.start()
  else
    local log_result = false
    local files = {}
    for i, param in ipairs(arg) do
      if param == "-d" then
        log_result = true
      else
        table.insert(files, param)
      end
    end
    for i, filename in ipairs(files) do
      if log_result then
        print("Loading " .. filename)
      end
      equinox.eval_file(filename, log_result)
    end
  end
end

function equinox.eval(str, log_result)
  return compiler:eval(str, log_result)
end

function equinox.eval_file(str, log_result)
  return compiler:eval_file(str, log_result)
end

if arg and arg[0] == "equinox.lua" then
  equinox.main(arg)
end

return equinox
