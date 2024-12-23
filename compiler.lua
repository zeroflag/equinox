-- Design:
-- Modeless
-- No rstack, native Lua return stack
-- Native Lua locals
-- No heap, here and ,
-- Native Lua tables
-- Lua interop
-- TODO:
-- 2dup cannot be defined
-- true/false
-- define dict via funcall
-- user defined control structues

local stack = require("stack")
local macros = require("macros")
local ops = require("ops")

-- TODO XXX
_G["macros"] = macros

local dict = {
  ["+"] = { name = "ops.add", imm = false },
  ["-"] = { name = "ops.sub", imm = false },
  ["*"] = { name = "ops.mul", imm = false },
  ["/"] = { name = "ops.div", imm = false },
  ["."] = { name = "ops.dot", imm = false },
  ["="] = { name = "ops.eq", imm = false },
  ["<"] = { name = "ops.lt", imm = false },
  ["swap"] = { name = "ops.swap", imm = false },
  ["over"] = { name = "ops.over", imm = false },
  ["drop"] = { name = "ops.drop", imm = false },
  ["dup"] = { name = "ops.dup", imm = false },
  ["if"] = { name = "macros._if", imm = true },
  ["then"] = { name = "macros._then", imm = true },
  ["else"] = { name = "macros._else", imm = true },
  [":"] = { name = "macros.colon", imm = true },
  [";"] = { name = "macros._end", imm = true },
}

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

function compiler.define(self, name, immediate)
  dict[name] = { ["name"] = name, imm = immediate }
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
  print(self.output)
  return self.output
end

function compiler.eval(self, text)
  return load(self:parse(text))()
end

function compiler.emit(self, token)
  self.output = self.output .. token .. "\n"
end

print(compiler:eval([[
  : nip swap drop ;
  : min over over < if drop else nip then ;
  : max over over < if nip else drop then ;

  4 5 min .
  5 2 min .

  4 5 max .
  6 2 max .
]]))
