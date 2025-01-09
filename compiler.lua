-- TODO
-- hyperstatic glob
-- fix Lua's accidental global
-- tab auto complete repl
-- a[i] syntax test
-- 14 -> var x syntax ?
-- basic syntax check
-- local words
-- debuginfo level

local stack = require("stack")
local macros = require("macros")
local Stack = require("stack_def")
local Dict = require("dict")
local Parser = require("parser")
local LineMapping = require("line_mapping")
local Output = require("output")
local interop = require("interop")
local ast = require("ast")
local unpack = table.unpack or unpack

local Compiler = {}

function Compiler.new(codegen, optimizer)
  local obj = {
    parser = nil,
    output = nil,
    code_start = 1,
    line_mapping = nil,
    optimizer = codegen,
    codegen = optimizer,
    chunk_name = "<<compiled eqx code>>",
    dict = Dict.new()
  }
  setmetatable(obj, {__index = Compiler})
  return obj
end

function Compiler:init(text)
  self.parser = Parser.new(text, self.dict)
  self.output = Output.new(self.chunk_name)
  self.line_mapping = LineMapping.new()
  self.output:append("local stack = require(\"stack\")")
  self.output:new_line()
  self.output:append("local aux = require(\"aux\")")
  self.output:new_line()
  self.ast = {}
  self.code_start = self.output:size()
end

function Compiler:word()
  return self.parser:next_item().token
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

function Compiler:lua_call(name, arity, vararg, void)
  if vararg then
    error(name .. " has variable/unknown number of arguments. " ..
          "Use " .. name .. "/n" .. " to specify arity. " ..
          "For example " .. name .. "/1")
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
  if void then
    table.insert(stmts, ast.func_call(name, unpack(params)))
  else
    table.insert(stmts, ast.push_many(
                   ast.func_call(name, unpack(params))))
  end
  return stmts
end

function Compiler:compile_token(item)
  if item.kind == "word" then
    local word = self.dict:find(item.token)
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

function Compiler:def_word(alias, name, immediate)
  self.dict:def_word(alias, name, immediate)
end

function Compiler:def_var(alias, name)
  self.dict:def_var(alias, name)
end

function Compiler:exec_macro(word)
  local mod, fun = self.dict:find(word).lua_name:match("^(.-)%.(.+)$")
  if mod == "macros" and type(macros[fun]) == "function" then
    return macros[fun](self)
  else
    error("Unknown macro " .. word)
  end
end

function Compiler:add_ast_nodes(nodes, item)
  if #nodes > 0 then
    for i, each in ipairs(nodes) do
      each.forth_line_number = item.line_number
      table.insert(self.ast, each)
    end
  else
    nodes.forth_line_number = item.line_number
    table.insert(self.ast, nodes) -- single node
  end
end

function Compiler:compile(text)
  self:init(text)
  local item = self.parser:next_item()
  while item do
    if item.kind == "macro" then
      local nodes = self:exec_macro(item.token)
      if nodes then self:add_ast_nodes(nodes, item) end
    else
      local nodes = self:compile_token(item)
      self:add_ast_nodes(nodes, item)
    end
    item = self.parser:next_item()
  end
  self.ast = self.optimizer:optimize_iteratively(self.ast)
  return self:generate_code()
end

function Compiler:generate_code()
  for i, ast in ipairs(self.ast) do
    local code = self.codegen:gen(ast)
    if ast.forth_line_number then
      self.line_mapping:set_target_source(
        ast.forth_line_number,
        self.output.line_number)
    end
    self.output:append(code)
    self.output:new_line()
  end
  return self.output
end

function Compiler:error_handler(err)
  local info = debug.getinfo(3, "lS")
  if info and info.source ~= self.chunk_name then
    info = debug.getinfo(4, "lS") -- if it was error/1
  end
  if info then
    local src_line_num =
      self.line_mapping:resolve_target(info.currentline)
    if src_line_num then
      print(string.format(
              "Error occurred at line: %d", src_line_num))
      for i = src_line_num -2, src_line_num +2 do
        local line = self.parser.lines[i]
        if line then
          local mark = "  "
          if i == src_line_num then mark = "=>" end
          print(string.format("%s%03d.  %s", mark, i , line))
        end
      end
      print()
    end
    print(string.format("Original Error: %d", info.currentline))
    print(debug.traceback())
  end
  return err
end

function Compiler:eval(text, log_result)
  local code = self:compile_and_load(text, log_result)
  local success, err = xpcall(code, function() self:error_handler() end)
  if success then
    return stack
  else
    error(err)
  end
end

function Compiler:compile_and_load(text, log_result)
  local out = self:compile(text)
  if log_result then
    io.write(self.output:text(self.code_start))
  end
  return out:load()
end

function Compiler:eval_file(path, log_result)
  local file = io.open(path, "r")
  if not file then
    error("Could not open file: " .. path)
  end
  local content = file:read("*a")
  file:close()
  return self:eval(content, log_result)
end

return Compiler
