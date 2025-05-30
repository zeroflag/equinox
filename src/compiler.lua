local macros = require("macros")
local Dict = require("dict")
local Parser = require("parser")
local LineMapping = require("line_mapping")
local Output = require("output")
local Source = require("source")
local Env = require("env")
local interop = require("interop")
local ast = require("ast")
local utils = require("utils")

local Compiler = {}
local marker = "<<equinox:"

function Compiler:new(optimizer, codegen)
  local obj = {
    parser = nil,
    source = Source:empty(),
    output = nil,
    chunks = {},
    code_start = 1,
    line_mapping = LineMapping:new(),
    env = nil,
    root_env = Env:new(nil, "root"),
    state = {},
    optimizer = optimizer,
    codegen = codegen,
    dict = Dict:new()
  }
  setmetatable(obj, {__index = self})
  obj.root_env:def_var_unsafe("true", "true")
  obj.root_env:def_var_unsafe("false", "false")
  obj.root_env:def_var_unsafe("nil", "NIL")
  obj:reset_state()
  return obj
end

function Compiler:reset_state()
  self.env = self.root_env
  self.state = {sequence = 1, do_loop_nesting = 1, last_word = nil}
end

function Compiler:init(source)
  self.source = source
  self.parser = Parser:new(source.text)
  self.output = Output:new(marker .. self.source.name .. ">>")
  self.output:append(
    "local stack, aux = require(\"stack\"), require(\"stack_aux\")")
  self.output:new_line()
  self.ast = {}
  self.code_start = self.output:size()
  if self.source.type == "chunk" then
    self.chunks[self.source.name] = self.source
  end
end

function Compiler:new_env(name)
  self.env = Env:new(self.env, name)
end

function Compiler:remove_env(name, item)
  if name and self.env.name ~= name then
    self:err("Incorrect nesting: " .. name, item)
  end
  if self.env.parent then
    self.env = self.env.parent
  else
    error("cannot drop root environment")
  end
end

function Compiler:def_var(name)
  return self.env:def_var(name)
end

function Compiler:def_global(name)
  return self.root_env:def_var(name)
end

function Compiler:has_var(name)
  return self.env:has_var(name)
end

function Compiler:find_var(name)
  return self.env:find_var(name)
end

function Compiler:var_names()
  return self.env:var_names()
end

function Compiler:word()
  local item = self:next_item()
  if item then
    return item.token
  else
    return nil
  end
end

function Compiler:next_item()
  return self.parser:next_item()
end

function Compiler:find(forth_name)
  return self.dict:find(forth_name)
end

function Compiler:reveal(lua_name)
  self.dict:reveal(lua_name)
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

function Compiler:def_word(alias, name, immediate, hidden)
  self.dict:def_word(alias, name, immediate, hidden)
end

function Compiler:err(message, item)
  self.source:show_lines(item.line_number, 1)
  self:reset_state()
  error(message .. " at line: " .. item.line_number)
end

function Compiler:warn(message, item)
  print("[WARN] " .. message .. " at line: " .. item.line_number)
end

function Compiler:exec_macro(item)
  local mod, fun = self.dict:find(item.token).lua_name:match("^(.-)%.(.+)$")
  if mod == "macros" and type(macros[fun]) == "function" then
    return macros[fun](self, item)
  else
    self:err("Unknown macro: " .. item.token, item)
  end
end

function Compiler:add_ast_nodes(nodes, item)
  if #nodes > 0 then
    for i, each in ipairs(nodes) do
      self:add_ast_nodes(each, item)
    end
  else
    nodes.forth_line_number = item.line_number
    table.insert(self.ast, nodes) -- single node
  end
end

function Compiler:valid_ref(name)
  return self.env:has_var(name) or interop.resolve_lua_obj(name)
end

function Compiler:compile_token(item)
  if item.kind == "symbol" then
    return ast.push(ast.literal("string", item.token:sub(2)))
  end
  if item.kind == "number" then
    return ast.push(ast.literal(item.kind, tonumber(item.token)))
  end
  if item.kind == "string" then
    return ast.push(ast.literal(item.kind, item.token:sub(2, -2)))
  end
  if item.kind == "word" then
    local word = self.dict:find(item.token)
    if word and word.immediate then
      return self:exec_macro(item)
    end
    if word and word.is_lua_alias then
      -- Prevent optimizer to overwrite original definition
      return utils.deepcopy(word.lua_name)
    end
    if self.env:has_var(item.token) then -- Forth variable
      return ast.push(
        ast.identifier(self.env:find_var(item.token).lua_name))
    end
    if word then -- Regular Forth word
      return ast.func_call(word.lua_name)
    end
    if interop.dot_or_colon_notation(item.token) then
      -- Table lookup: math.pi or tbl.key or method call a:b a:b.c
      local parts = interop.explode(item.token)
      local name = parts[1]
      if self:valid_ref(name) then
        if self.env:has_var(name) then
          parts[1] = self.env:find_var(name).lua_name
        end
        -- This can result multiple values, like img:getDimensions,
        -- a single value like tbl.key or str:upper, or void like img:draw
        if interop.is_lua_prop_lookup(item.token) then
          return ast.push(ast.identifier(interop.join(parts)))
        else
          return ast.push_many(ast.identifier(interop.join(parts)))
        end
      else
        self:err("Unkown variable: " .. name .. " in expression: " .. item.token, item)
      end
    end
    if interop.resolve_lua_obj(item.token) then
      -- Lua globals from _G, such as math, table, io
      return ast.push(ast.identifier(item.token))
    end
  end
  self:err("Unknown token: " .. item.token .. " kind: " .. item.kind, item)
end

function Compiler:compile(source)
  self:init(source)
  local item = self.parser:next_item()
  while item do
    local node = self:compile_token(item)
    if node then self:add_ast_nodes(node, item) end
    item = self.parser:next_item()
  end
  self.ast = self.optimizer:optimize_iteratively(self.ast)
  return self:generate_code()
end

function Compiler:generate_code()
  for i, ast in ipairs(self.ast) do
    local code = self.codegen:gen(ast)
    if ast.forth_line_number then
      self.line_mapping:map_target_to_source(
        self.source.name,
        ast.forth_line_number,
        self.output.line_number)
    end
    if ast.name == "func_header" then
      local word = self.dict:find_by_lua_name(ast.func_name)
      -- methods are not stored in dict
      if word then word.line_number = self.output.line_number end
    end
    self.output:append(code)
    self.output:new_line()
    if ast.name == "end_func" then
      local word = self.dict:find_by_lua_name(ast.func_name)
      if word then -- methods are not stored in dict
        word.code = string.gsub(
          self.output:text(word.line_number), "[\n\r]+$", "")
      end
    end
  end
  return self.output
end

function Compiler:traceback(err)
  local info
  local file = "N/A"
  for level = 1, math.huge do
    info = debug.getinfo(level, "Sl")
    if not info then
      break
    end
    if info.source and
       info.currentline > 0 and
       info.source:sub(1, #marker) == marker
    then
      file = info.source:match(marker .. "(.-)>>")
      local src_line_num =
        self.line_mapping:resolve_target(file, info.currentline)
      if src_line_num then
        io.stderr:write(string.format(
                "  File \"%s\", line %d (%d)\n", file, src_line_num, info.currentline))
        if utils.exists(file) then
          Source:from_file(file):show_lines(src_line_num, 1)
        elseif self.chunks[file] then
          self.chunks[file]:show_lines(src_line_num, 1)
        end
      end
    end
  end
  return err
end

function Compiler:eval_file(path, log_result)
  return self:_eval(Source:from_file(path), log_result)
end

function Compiler:eval_text(text, log_result)
  return self:_eval(Source:from_text(text), log_result)
end

function Compiler:compile_and_load(source, log_result) -- used by REPL for multiline
  local out = self:compile(source)
  if log_result then
    io.write(self.output:text(self.code_start))
  end
  return out:load()
end

function Compiler:_eval(source, log_result)
  local code, err = self:compile_and_load(source, log_result, path)
  if err then
    self:traceback(err) -- error during load
    error(err)
  end
  local success, result = xpcall(code, function(e) return self:traceback(e) end)
  if success then
    return result
  else
    error(result) -- error during execute
  end
end

return Compiler
