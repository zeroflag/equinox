do
local _ENV = _ENV
package.preload[ "ast" ] = function( ... ) local arg = _G.arg;
local ast = {}

function ast.func_header(func_name, arity, void)
  return {
    name = "func_header",
    func_name = func_name,
    arity = arity,
    void = void
  }
end

function ast.func_call(func_name, ...)
  return {
    name = "func_call",
    func_name = func_name,
    args = {...}
  }
end

function ast.code_seq(...)
  return {name = "code_seq", code = {...}}
end

function ast.pop()
  return {name = "stack_op", op  = "pop"}
end

function ast.pop2nd()
  return {name = "stack_op", op  = "pop2nd"}
end

function ast.pop3rd()
  return {name = "stack_op", op  = "pop3rd"}
end

function ast.stack_op(operation)
  return {name = "stack_op", op = operation}
end

function ast.aux_op(operation)
  return {name = "aux_op", op = operation}
end

function ast.push(item)
  return {name  = "push", item = item}
end

function ast.aux_push(item)
  return {name  = "push_aux", item = item}
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

function ast.bin_op(operator, param1, param2)
  return {
    name = "bin_op",
    op = operator,
    p1 = param1,
    p2 = param2
  }
end

function ast.unary_op(operator, operand)
  return {name = "unary_op", op = operator, p1 = operand}
end

function ast.assignment(var, exp)
  return {name = "assignment", var  = var, exp  = exp}
end

function ast.def_local(variable)
  return {name = "local", var = variable}
end

function ast.new_table()
  return {
    name = "table_new"
  }
end

function ast.table_at(tbl, key)
  return {
    name = "table_at",
    key = key,
    tbl = tbl
  }
end

function ast.table_put(tbl, key, value)
  return {
    name = "table_put",
    tbl = tbl,
    key = key,
    value = value
  }
end

function ast._if(cond, body)
  return {
    name = "if",
    cond = cond,
    body = body
  }
end

function ast.keyword(keyword)
  return {name = "keyword", keyword = keyword}
end

function ast.identifier(id)
  return {name = "identifier", id = id}
end

function ast._return()
  return {name = "return"}
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
package.preload[ "aux" ] = function( ... ) local arg = _G.arg;
local Stack = require("stack_def")
local aux = Stack.new("aux-stack")

return aux
end
end

do
local _ENV = _ENV
package.preload[ "codegen" ] = function( ... ) local arg = _G.arg;
local CodeGen = {}

function CodeGen.new()
  local obj = {}
  setmetatable(obj, {__index = CodeGen})
  return obj
end

function CodeGen.gen(self, ast)
  if "stack_op" == ast.name then
    return "stack:" .. ast.op .. "()"
  end
  if "aux_op" == ast.name then
    return "aux:" .. ast.op .. "()"
  end
  if "push" == ast.name then
    return string.format("stack:push(%s)", self:gen(ast.item))
  end
  if "push_aux" == ast.name then
    return string.format("aux:push(%s)", self:gen(ast.item))
  end
  if "unary_op" == ast.name then
    return string.format("%s %s", ast.op, self:gen(ast.p1))
  end
  if "bin_op" == ast.name then
    return string.format(
      "%s %s %s", self:gen(ast.p1), ast.op, self:gen(ast.p2))
  end
  if "local" == ast.name then
    return "local " .. ast.var
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
    return string.format("while(%s)do", self:gen(ast.cond))
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
      return string.format(
        "for %s,%s in %s do",
        ast.loop_var1, ast.loop_var2, self:gen(ast.iterable))
  end
  if "pairs" == ast.name then
    return string.format("pairs(%s)", self:gen(ast.iterable))
  end
  if "ipairs" == ast.name then
    return string.format("ipairs(%s)", self:gen(ast.iterable))
  end
  if "if" == ast.name then
    if ast.body then
      return "if " .. self:gen(ast.cond) .. " then " .. self:gen(ast.body) .. " end"
    else
      return "if " .. self:gen(ast.cond) .. " then"
    end
  end
  if "keyword" == ast.name then return ast.keyword end
  if "identifier" == ast.name then return ast.id end
  if "return" == ast.name then return "do return end" end
  if "table_new" == ast.name then return "stack:push({})" end
  if "table_at" == ast.name then
    return string.format("stack:push(%s[%s])",
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
  if "code_seq" == ast.name then
    local result = ""
    for i, c in ipairs(ast.code) do
      result = result .. self:gen(c)
      if i < #ast.code then
        result = result .. "\n"
      end
    end
    return result
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

return CodeGen
end
end

do
local _ENV = _ENV
package.preload[ "compiler" ] = function( ... ) local arg = _G.arg;
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
      self.output:append(self.codegen:gen(ast.func_call(word.lua_name)))
    else
      -- Forth variable
      self.output:append(self.codegen:gen(ast.push(ast.identifier(word.lua_name))))
    end
  elseif item.kind == "literal" then
    if item.subtype == "symbol" then
      self.output:append(self.codegen:gen(ast.push(ast.literal("string", item.token:sub(2)))))
    elseif item.subtype == "number" then
      self.output:append(self.codegen:gen(ast.push(ast.literal(item.subtype, tonumber(item.token)))))
    elseif item.subtype == "string" then
      self.output:append(self.codegen:gen(ast.push(ast.literal(item.subtype, item.token:sub(2, -2)))))
    else
      error("Unkown literal: " .. item.kind)
    end
  elseif item.kind == "lua_table_lookup" or
         item.kind == "lua_array_lookup" then
    if item.resolved then
      self.output:append(self.codegen:gen(ast.push(ast.identifier(item.token))))
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
dict.def_macro("-rot", "macros.mrot")
dict.def_macro("nip", "macros.nip")
dict.def_macro("drop", "macros.drop")
dict.def_macro("dup", "macros.dup")
dict.def_macro("2dup", "macros.dup2")
dict.def_macro("tuck", "macros.tuck")
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
dict.def_macro("then", "macros._end")
dict.def_macro("else", "macros._else")
dict.def_macro("begin", "macros._begin")
dict.def_macro("until", "macros._until")
dict.def_macro("while", "macros._while")
dict.def_macro("repeat", "macros._end")
dict.def_macro("again", "macros._end")
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
dict.def_macro("to:", "macros._to")
dict.def_macro("step:", "macros._step")
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

function interop.is_lua_array_lookup(token)
  return string.match(token, ".+%[.+%]")
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
local ast = require("ast")

-- TODO remove all compiler params

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
  return ast.push(ast.bin_op(">", ast.pop(), ast.pop()))
end

function macros.lte()
  return ast.push(ast.bin_op(">=", ast.pop(), ast.pop()))
end

function macros.gt()
  return ast.push(ast.bin_op("<", ast.pop(), ast.pop()))
end

function macros.gte()
  return ast.push(ast.bin_op("<=", ast.pop(), ast.pop()))
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
  return ast.table_at(ast.pop2nd(), ast.pop())
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

function macros.dot()
  return ast.code_seq(
    ast.func_call("io.write", ast.func_call("tostring", ast.pop())),
    ast.func_call("io.write", ast.literal("string", " ")))
end

function macros.cr()
  return ast.func_call("print")
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
  return ast.func_header(lua_name, arity, void)
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
  return ast.def_local(name)
end

function macros.assignment(compiler)
  local variable = compiler:word()
  return ast.assignment(variable, ast.pop())
end

function macros._if()
  return ast._if(ast.pop())
end

function macros._else()
  return ast.keyword("else")
end

function macros._begin()
  return ast._while(ast.literal("boolean", "true"))
end

function macros._until()
  return ast.code_seq(
    ast._if(ast.pop(), ast.keyword("break")),
    ast.keyword("end"))
end

function macros._while()
  return ast._if(ast.unary_op("not", ast.pop()), ast.keyword("break"))
end

function macros._case() -- simulate goto with break, in pre lua5.2 since GOTO was not yet supported
  return ast.keyword("repeat")
end

function macros._of()
  return ast.code_seq(
    ast.stack_op("over"),
    ast._if(ast.bin_op("==", ast.pop(), ast.pop())),
    ast.pop() -- drop selector
  )
end

function macros._endof() -- GOTO endcase
  return ast.code_seq(ast.keyword("break"), ast.keyword("end"))
end

function macros._endcase()
  return ast._until(ast.literal("boolean", "true"))
end

function macros._exit()
  return ast._return()
end

-- TODO this might overwrite user defined i/j ?
function macros._i()
  return ast.push(ast.aux_op("tos"))
end

-- TODO this might overwrite user defined i/j ?
function macros._j()
  return ast.push(ast.aux_op("tos2"))
end

function macros.unloop()
  return ast.aux_op("pop")
end

function macros._do(compiler)
  local var = gen_id("loop_var")
  return ast.code_seq(
    ast._for(
      var, ast.pop(),
      ast.bin_op("-", ast.pop(), ast.literal("number", 1)),
      nil),
    ast.aux_push(ast.identifier(var)))
end

function macros._loop()
  return ast.code_seq(
    ast.aux_op("pop"), -- unloop i/j
    ast.keyword("end"))
end

function macros.for_ipairs(compiler)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  -- TODO should be removed or we should maintain proper scope
  compiler:def_var(var_name1, var_name1)
  compiler:def_var(var_name2, var_name2)
  return ast._foreach(var_name1, var_name2, ast._ipairs(ast.pop()))
end

function macros.for_pairs(compiler)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  -- TODO should be removed or we should maintain proper scope
  compiler:def_var(var_name1, var_name1)
  compiler:def_var(var_name2, var_name2)
  return ast._foreach(var_name1, var_name2, ast._pairs(ast.pop()))
end

function macros._to(compiler)
  local loop_var = compiler:word()
  -- TODO should be removed or we should maintain proper scope
  compiler:def_var(loop_var, loop_var)
  return ast._for(loop_var, ast.pop2nd(), ast.pop(), nil)
end

function macros._step(compiler)
  local loop_var = compiler:word()
  -- TODO should be removed or we should maintain proper scope
  compiler:def_var(loop_var, loop_var)
  return ast._for(loop_var, ast.pop3rd(), ast.pop2nd(), ast.pop(), nil)
end

function macros._end()
  return ast.keyword("end")
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
package.preload[ "parser" ] = function( ... ) local arg = _G.arg;
local interop = require("interop")

local Parser = {}

function Parser.new(source, dict)
  local obj = {index = 1, source = source, dict = dict}
  setmetatable(obj, {__index = Parser})
  return obj
end

function Parser.parse_all(self)
  local result = {}
  local item = self:next_item()
  while item do
    table.insert(result, item)
    item = self:next_item()
  end
  return result
end

function Parser.next_item(self)
  local token = ""
  local begin_str = false
  local stop = false
  local kind = "word"
  while not self:ended() and not stop do
    local chr = self:next_chr()
    if is_quote(chr) then
      if begin_str then
        stop = true
      else
        kind = "string"
        begin_str = true
      end
    end
    if is_whitespace(chr) and not begin_str then
      if #token > 0 then
        self.index = self.index -1 -- don't consume next WS as it breaks single line comment
        stop = true
      end
    else
      token = token .. chr
    end
  end
  if token == "" then
    return nil
  end
  if token:match("^:.+") then kind = "symbol" end
  return self:parse_word(token, kind)
end

function Parser.next_chr(self)
  local chr = self.source:sub(self.index, self.index)
  self.index = self.index + 1
  return chr
end

function Parser.parse_word(self, token, kind)
  local word = self.dict.find(token)
  if kind == "word" and word and word.immediate
  then
    return {token = token, kind = "macro"}
  end
  if kind == "string" then
    return literal(token, "string")
  end
  if kind == "symbol" then
    return literal(token, "symbol")
  end
  if word then
    if word.is_lua_alias then
      -- Known lua alias
      local res = interop.resolve_lua_func_with_arity(word.lua_name)
      return lua_func_call(token, res)
    else
      -- Known Forth word
      return {token = token, kind = "word"}
    end
  end
  local num = tonumber(token)
  if num then
    return literal(token, "number")
  end
  local res = interop.resolve_lua_method_call(token)
  if res then
    -- Lua method call such as obj:method/3
    return lua_method_call(token, res)
  end
  local res = interop.resolve_lua_func_with_arity(token)
  if res then
    -- Lua function call such as math.max/2
    return lua_func_call(token, res)
  end
  if interop.is_lua_prop_lookup(token) then
    -- Table lookup
    local lua_obj = interop.resolve_lua_obj(token)
    -- best effort to check if it's valid lookup
    if lua_obj or self.dict.find(token:match("^[^.]+")) then
      return lua_table_lookup(token, true)
    else
      return lua_table_lookup(token, false)
    end
  end
  if interop.is_lua_array_lookup(token) then
    -- TODO try to resolve
    return lua_array_lookup(token, true)
  end
  return unknown(token)
end

function Parser.ended(self)
  return self.index > #self.source
end

function lua_func_call(token, res)
  return {
    token = token,
    kind = "lua_func_call",
    name = res.name,
    arity = res.arity,
    vararg = res.vararg,
    void = res.void
  }
end

function lua_method_call(token, res)
  return {
    token = token,
    kind = "lua_method_call",
    name = res.name,
    arity = res.arity,
    vararg = res.vararg,
    void = res.void
  }
end

function lua_table_lookup(token, resolved)
  return {token = token, kind = "lua_table_lookup", resolved = resolved}
end

function lua_array_lookup(token, resolved)
  return {token = token, kind = "lua_array_lookup", resolved = resolved}
end

function literal(token, subtype)
  return {token = token, kind = "literal", subtype = subtype}
end

function unknown(token)
  return {token = token, kind = "unknown"}
end

function is_quote(chr)
  return chr:match('"')
end

function is_whitespace(chr)
  return chr:match("%s")
end

return Parser
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
- log-on "turn on logging"
- log-off "turn off logging"
- load-file <path> "load an eqx file"
- bye "exit repl"
- help "show this help"
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

function trim(str)
  return str:match("^%s*(.-)%s*$")
end

function repl.process_commands()
  local command = trim(repl.input)
  if command == "bye" then
    os.exit(0)
  end
  if command == "help" then
    show_help()
    return true
  end
  if command == "log-on" then
    repl.log_result = true
    print("Log turned on")
    return true
  end
  if command == "log-off" then
    repl.log_result = false
    print("Log turned off")
    return true
  end
  local path = command:match("load%-file%s+(.+)")
  if path then
    safe_call(function() compiler:eval_file(path) end)
    return true
  end
  return false
end

function repl.print_err(result)
  print("\27[91m" .. "Red Alert: " .. "\27[0m" .. result)
end

function repl.print_ok()
  if stack:depth() > 0 then
    print("\27[92m" .. "OK(".. stack:depth()  .. ")" .. "\27[0m")
  else
    print("\27[92mOK\27[0m")
  end
end

function safe_call(func)
  local success, result = pcall(func)
  if success then
    repl.print_ok()
  else
    repl.print_err(result)
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
        safe_call(function() result() end)
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
local Stack = {}
local NIL = "__NIL__"

function Stack.new(name)
  local obj = {stack = {nil,nil,nil,nil,nil,nil,nil,nil}, name = name}
  setmetatable(obj, {__index = Stack})
  return obj
end

function Stack.push(self, e)
  self.stack[#self.stack + 1] = (e ~= nil and e or NIL)
end

function Stack.push_many(self, ...)
  local args = {...}
  local stack = self.stack
  for i = 1, #args do
    stack[#stack + 1] = (args[i] ~= nil and args[i] or NIL)
  end
end

function Stack.pop(self)
  local item = table.remove(self.stack)
  if not item then
    error("Stack underflow: " .. self.name)
  end
  return item ~= NIL and item or nil
end

function Stack.pop2nd(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  local item = table.remove(self.stack, n - 1)
  return item ~= NIL and item or nil
end

function Stack.pop3rd(self)
  local n = #self.stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local item = table.remove(self.stack, n - 2)
  return item ~= NIL and item or nil
end

function Stack.swap(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  self.stack[n], self.stack[n - 1] = self.stack[n - 1], self.stack[n]
end

function Stack.rot(self)
  local n = #self.stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local new_top = self.stack[n-2]
  table.remove(self.stack, n - 2)
  self.stack[n] = new_top
end

function Stack.mrot(self)
  local n = #self.stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local temp = table.remove(self.stack, n)
  table.insert(self.stack, n - 2, temp)
end

function Stack.over(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  self.stack[n + 1] = self.stack[n - 1]
end

function Stack.tuck(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  table.insert(self.stack, n - 1, self.stack[n])
end

function Stack.nip(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  table.remove(self.stack, n - 1)
end

function Stack.dup(self)
  local n = #self.stack
  if n < 1 then
    error("Stack underflow: " .. self.name)
  end
  self.stack[n + 1] = self.stack[n]
end

function Stack.dup2(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  local tos1 = self.stack[n]
  local tos2 = self.stack[n - 1]
  self.stack[n + 1] = tos2
  self.stack[n + 2] = tos1
end

function Stack.tos(self)
  return self.stack[#self.stack]
end

function Stack.tos2(self)
  return self.stack[#self.stack - 1]
end

function Stack._and(self)
  local a, b = self:pop(), self:pop()
  self:push(a and b)
end

function Stack._or(self)
  local a, b = self:pop(), self:pop()
  self:push(a or b)
end

function Stack.depth(self)
  return #self.stack
end

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
