-- Design:
-- Modeless
-- No rstack, native Lua return stack
-- Native Lua locals
-- No heap, here and ,
-- Native Lua tables
-- Lua interop
-- TODO:
-- user defined control structues
-- var/local scopes
-- case
-- single line comment
-- begin while repeat
-- for
-- symbols
-- hyperstatic glob
-- second stack
-- benchmarks
-- fix Lua's accidental global
-- table

local stack = require("stack")
local macros = require("macros")
local ops = require("ops")
local dict = require("dict")
local Input = require("input")
local Output = require("output")
local interop = require("interop")

-- TODO XXX
_G["macros"] = macros

local compiler = { input = nil, output = nil }

function compiler.word(self)
  return self.input:parse()
end

function compiler.emit_string(self, token)
  self:emit_line("ops.lit(" .. token .. ")")
end

function compiler.emit_word(self, word)
  if word.callable then
    self:emit_line(word.name .. "()")
  else
    self:emit_line("ops.lit(" .. word.name .. ")")
  end
end

function compiler.emit_number(self, num)
  self:emit_line("ops.lit(" .. num .. ")")
end

function compiler.emit_lua_call(self, name, arity, vararg)
  if vararg then
    error(name .. " has variable number of arguments." ..
          "Use " .. name .. "/n" .. " to specify arity.")
  end
  local params = ""
  for i = 1, arity do
    params = params .. "stack.pop()"
    if i < arity then
      params = params .. ", "
    end
  end
  -- TODO reverse the order of params?
  self:emit_line("stack.push(" .. name .. "(" .. params .. "))")
end

function compiler.compile_token(self, token, kind)
  if kind == "string" then
    self:emit_string(token)
  else
    local word = dict.find(token)
    if word then
      self:emit_word(word)
    else
      local num = tonumber(token)
      if num then
        self:emit_number(num)
      else
        local res = interop.resolve_lua_func_with_arity(token)
        if res then
          self:emit_lua_call(res.name, res.arity, res.vararg)
        else
          error("Word not found: '" .. token .. "'")
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
  dict.defvar("true", "true")
  dict.defvar("false", "false")
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
    error("Could not open file: " .. path)
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
