-- hyperstatic glob
-- optize output
-- i shadows user defined i in pairs:/ipairs:
-- symbol & instead of :
-- Stack as Macro
-- fix Lua's accidental global
-- tab auto complete repl
-- var with dash generates error
-- line numbers + errors
-- a[i] syntax test
-- TOS optimiziation
-- 14 -> var x syntax ?

local stack = require("stack")
local macros = require("macros")
local Stack = require("stack_def")
local dict = require("dict")
local Parser = require("parser")
local Output = require("output")
local interop = require("interop")
local CodeGen = require("codegen")
local ast = require("ast")

local compiler = { parser = nil, output = nil, code_start = 1 }

function compiler.word(self)
  return self.parser:next_item().token
end

function compiler.next(self)
  return self.parser:next_chr()
end

function compiler.word_list(self)
  return dict.word_list()
end

function compiler.alias(self, lua_name, forth_alias)
  return dict.def_lua_alias(lua_name, forth_alias)
end

function compiler.lua_call(self, name, arity, vararg, void)
  if vararg then
    error(name .. " has variable/unknown number of arguments. " ..
          "Use " .. name .. "/n" .. " to specify arity. " ..
          "For example " .. name .. "/1")
  end
  local params = {}
  local stmts = {}
  if arity > 0 then
    for i = 1, arity do -- TODO gen name
      table.insert(params, ast.identifier("__p" .. i))
      table.insert(stmts,
        ast.init_local("__p" .. (arity -i +1), ast.pop()))
    end
  end
  local unpack = table.unpack or unpack
  if void then
    table.insert(stmts, ast.func_call(name, unpack(params)))
  else
    table.insert(stmts, ast.push_many(
                   ast.func_call(name, unpack(params))))
  end
  return ast.code_seq(unpack(stmts))
end

function compiler.compile_token(self, item)
  if item.kind == "word" then
    local word = dict.find(item.token)
    if word.callable then
      -- Forth word
      return ast.func_call(word.lua_name)
    else
      -- Forth variable
      return ast.push(ast.identifier(word.lua_name))
    end
  elseif item.kind == "literal" then
    if item.subtype == "symbol" then
      return ast.push(ast.literal("string", item.token:sub(2)))
    elseif item.subtype == "number" then
      return ast.push(ast.literal(item.subtype, tonumber(item.token)))
    elseif item.subtype == "string" then
      return ast.push(ast.literal(item.subtype, item.token:sub(2, -2)))
    else
      error("Unkown literal: " .. item.kind)
    end
  elseif item.kind == "lua_table_lookup" or
         item.kind == "lua_array_lookup" then
    if item.resolved then
      return ast.push(ast.identifier(item.token))
    else
      error("Unknown table lookup: " .. item.token)
    end
  elseif item.kind == "lua_func_call" or
         item.kind == "lua_method_call" then
    return self:lua_call(item.name, item.arity, item.vararg, item.void)
  else
    error("Word not found: '" .. item.token .. "'" .. " kind: " .. item.kind)
  end
end

function compiler.def_word(self, alias, name, immediate)
  dict.def_word(alias, name, immediate)
end

function compiler.def_var(self, alias, name)
  dict.def_var(alias, name)
end

function compiler.exec_macro(self, word)
  local mod, fun = dict.find(word).lua_name:match("^(.-)%.(.+)$")
  if mod == "macros" and type(macros[fun]) == "function" then
    local result = macros[fun](self)
    if result then
      self.output:append(self.codegen:gen(result))
      self.output:new_line()
    end
  else
    error("Unknown macro " .. word)
  end
end

function compiler.init(self, text)
  self.parser = Parser.new(text, dict)
  self.output = Output.new()
  self.codegen = CodeGen.new()
  self.output:append("local stack = require(\"stack\")")
  self.output:new_line()
  self.output:append("local aux = require(\"aux\")")
  self.output:new_line()
  self.code_start = self.output:size()
  dict.def_var("true", "true")
  dict.def_var("false", "false")
  dict.def_var("nil", "NIL")
end

function compiler.compile(self, text)
  self:init(text)
  local item = self.parser:next_item()
  while item do
    if item.kind == "macro" then
      self:exec_macro(item.token)
    else
      self.output:append(self.codegen:gen(self:compile_token(item)))
      self.output:new_line()
    end
    item = self.parser:next_item()
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
    io.write(self.output:text(self.code_start))
  end
  return out:load()
end

function compiler.eval_file(self, path, log_result)
  local file = io.open(path, "r")
  if not file then
    error("Could not open file: " .. path)
  end
  local content = file:read("*a")
  file:close()
  return self:eval(content, log_result)
end

return compiler
