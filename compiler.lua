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
-- aliases
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

function compiler.alias(self, lua_name, forth_alias)
  return dict.def_lua_alias(lua_name, forth_alias)
end

function compiler.emit_lit(self, token)
  self:emit_line("ops.lit(" .. token .. ")")
end

function compiler.emit_symbol(self, token)
  self:emit_lit('"' .. token:sub(2) .. '"')
end

function compiler.emit_word(self, word)
  if word.callable then
    self:emit_line(word.lua_name .. "()")
  else
    self:emit_line("ops.lit(" .. word.lua_name .. ")")
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
    if word and not word.is_lua_alias then
      self:emit_word(word)
    else
      local num = tonumber(token)
      if num then
        self:emit_lit(num)
      else
        local res = interop.resolve_lua_func_with_arity(token)
        if word and word.is_lua_alias then
          res = interop.resolve_lua_func_with_arity(word.lua_name)
        end
        if res then
          self:emit_lua_call(res.name, res.arity, res.vararg, res.void)
        else
          err.abort("Word not found: '" .. token .. "'")
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
  self:emit_line("local ops = require(\"ops\")")
  self:emit_line("local stack = require(\"stack\")")
  self:emit_line("local aux = require(\"aux\")")
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
  print(self.output:text())
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
