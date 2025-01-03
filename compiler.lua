-- TODOnp:
-- user defined control structues
-- var/local scopes
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

function compiler.emit_push(self, token)
  self:emit_line("stack:push(" .. token .. ")")
end

function compiler.emit_lua_call(self, name, arity, vararg, void)
  if vararg then
    error(name .. " has variable/unknown number of arguments. " ..
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

function compiler.compile_token(self, item)
  if item.kind == "word" then
    local word = dict.find(item.token)
    if word.callable then
      -- Forth word
      self:emit_line(word.lua_name .. "()")
    else
      -- Forth variable
      self:emit_push(word.lua_name)
    end
  elseif item.kind == "literal" then
    if item.subtype == "string" then
      self:emit_push(item.token)
    elseif item.subtype == "symbol" then
      self:emit_push('"' .. item.token:sub(2) .. '"')
    elseif item.subtype == "number" then
      self:emit_push(tonumber(item.token))
    else
      error("Unkown literal type: " .. item.subtype)
    end
  elseif item.kind == "lua_table_lookup" or
         item.kind == "lua_array_lookup" then
    if item.resolved then
      self:emit_push(item.token)
    else
      error("Unknown table lookup: " .. item.token)
    end
  elseif item.kind == "lua_func_call" or
         item.kind == "lua_method_call" then
    self:emit_lua_call(item.name, item.arity, item.vararg, item.void)
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
      self.output:append(gen(result))
      self.output:new_line()
    end
  else
    error("Unknown macro " .. word)
  end
end

function compiler.init(self, text)
  self.parser = Parser.new(text, dict)
  self.output = Output.new()
  self:emit_line("local stack = require(\"stack\")")
  self:emit_line("local aux = require(\"aux\")")
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
      self:compile_token(item)
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

function compiler.emit_line(self, token)
  self:emit(token)
  self.output:new_line()
end

function compiler.emit(self, token)
  self.output:append(token)
end

-- TODO work in progress, extract elsewhere
function gen(ast)
  if "stack_op" == ast.name then
    return "stack:" .. ast.op .. "()"
  end
  if "unary_op" == ast.name then
    return string.format(
      "stack:push(%s %s)", ast.op, gen(ast.p1))
  end
  if "bin_op" == ast.name then
    if ast.use_locals then -- TODO gen local var names
      return string.format([[
local __a, __b = %s, %s
stack:push(__a %s __b)
]], gen(ast.p1), gen(ast.p2), ast.op)
    else
      return string.format(
        "stack:push(%s %s %s)", gen(ast.p1), ast.op, gen(ast.p2))
    end
  end
  if "local" == ast.name then
    return "local " .. ast.var
  end
  if "assignment" == ast.name then
    return ast.var .. " = " .. gen(ast.exp)
  end
  if "for" == ast.name and not ast.step then
      return string.format(
        "for %s=%s,%s do",
        ast.loop_var, gen(ast.start), gen(ast.stop))
  end
  if "for" == ast.name and ast.step then
      return string.format(
        "for %s=%s,%s,%s do",
        ast.loop_var, gen(ast.start), gen(ast.stop), gen(ast.step))
  end
  if "for_each" == ast.name then
      return string.format(
        "for %s,%s in %s do",
        ast.loop_var1, ast.loop_var2, gen(ast.iterable))
  end
  if "pairs" == ast.name then
    return string.format("pairs(%s)", gen(ast.iterable))
  end
  if "ipairs" == ast.name then
    return string.format("ipairs(%s)", gen(ast.iterable))
  end
  if "if" == ast.name then
    return "if " .. gen(ast.cond) .. " then"
  end
  if "else" == ast.name then return "else" end
  if "end" == ast.name then return "end" end
  if "repeat" == ast.name then return "repeat" end
  if "return" == ast.name then return "do return end" end
  if "table_new" == ast.name then return "stack:push({})" end
  if "table_at" == ast.name then
    return string.format("stack:push(%s[%s])",
                         gen(ast.tbl), gen(ast.key))
  end
  if "table_put" == ast.name then
    return string.format(
      "%s[%s]=%s",
      gen(ast.tbl), gen(ast.key), gen(ast.value))
  end
  if "func_header" == ast.name then
    if ast.arity == 0 then
      return "function " .. ast.func_name .. "()"
    else
      local result = "function " .. ast.func_name .. "("
      for i = 1, ast.arity do
        result = result .. "__a" .. i
        if i < ast.arity then result = result .. "," end
      end
      result = result .. ")\n"
      for i = 1, ast.arity do
        result = result .. "stack:push(__a" .. i .. ")\n"
      end
      return result
    end
  end
  error("Unknown AST: " .. ast.name)
end

return compiler
