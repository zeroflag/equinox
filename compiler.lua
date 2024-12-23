-- Design:
-- Modeless
-- No rstack, native Lua return stack
-- Native Lua locals
-- No heap, here and ,
-- Native Lua tables
-- Lua interop
-- TODO:
-- true/false
-- user defined control structues

local stack = require("stack")
local macros = require("macros")
local ops = require("ops")
local dict = require("dict")

-- TODO XXX
_G["macros"] = macros

local compiler = { source = "", index = 1, output = "" }

function compiler.word(self)
  local word = ""
  while self.index <= #self.source do
    local chr = self.source:sub(self.index, self.index)
    if chr:match("%s") then
      if #word > 0 then
        break
      end
    else
      word = word .. chr
    end
    self.index = self.index + 1
  end
  return word
end

function compiler.compile(self, token)
  if dict[token] then
    self:emit("  " .. dict[token].name .. "()")
  else
    local num = tonumber(token)
    if num == nil then
      error("Word not found: '" .. token .. "'")
    else
      self:emit("  ops.lit(" .. num .. ")")
    end
  end
end

function compiler.define(self, alias, name, immediate)
  dict.define(alias, name, immediate)
end

function compiler.exec(self, word)
  local mod, fun = dict[word].name:match("^(.-)%.(.+)$")
  _G[mod][fun](self)
end

function compiler.init(self, text)
  self.source = text
  self.index = 1
  self.output = ""
  self:emit("local ops = require(\"ops\")")
  self:emit("local stack = require(\"stack\")")
end

function compiler.parse(self, text)
  self:init(text)
  local token = self:word()
  while token ~= "" do
    if dict[token] and dict[token].imm then
      self:exec(token)
    else
      self:compile(token)
    end
    token = self:word()
  end
  --print(self.output)
  return self.output
end

function compiler.eval(self, text)
  load(self:parse(text))()
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

function compiler.emit(self, token)
  self.output = self.output .. token .. "\n"
end

return compiler
