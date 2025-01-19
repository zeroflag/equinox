-- TODO
-- tab auto complete repl (linenoise/readline)
-- basic syntax check
-- debuginfo level (assert)
-- var names with dash
-- reveal word only after ;
-- don't sanitize methods
-- : mod.my-method error while : my-word works

local macros = require("macros")
local Dict = require("dict")
local Parser = require("parser")
local LineMapping = require("line_mapping")
local Output = require("output")
local Env = require("env")
local interop = require("interop")
local ast = require("ast")
local utils = require("utils")

local Compiler = {}

function Compiler:new(codegen, optimizer)
  local obj = {
    parser = nil,
    output = nil,
    code_start = 1,
    line_mapping = nil,
    env = nil,
    root_env = Env.new(nil, "root"),
    state = {},
    optimizer = codegen,
    codegen = optimizer,
    chunk_name = "<<compiled eqx code>>",
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

function Compiler:init(text)
  self.parser = Parser.new(text)
  self.output = Output.new(self.chunk_name)
  self.line_mapping = LineMapping.new()
  self.output:append("local stack = require(\"stack\")")
  self.output:new_line()
  self.output:append("local aux = require(\"aux\")")
  self.output:new_line()
  self.ast = {}
  self.code_start = self.output:size()
end

function Compiler:new_env(name)
  self.env = Env.new(self.env, name)
end

function Compiler:remove_env(name)
  if name and self.env.name ~= name then
    error("Incorrect nesting: " .. name)
  end
  if self.env.parent then
    self.env = self.env.parent
  else
    error("cannot drop root environment")
  end
end

function Compiler:def_var(name)
  self.env:def_var(name)
end

function Compiler:def_global(name)
  self.root_env:def_var(name)
end

function Compiler:has_var(name)
  return self.env:has_var(name)
end

function Compiler:word()
  return self:next_item().token
end

function Compiler:next_item()
  return self.parser:next_item()
end

function Compiler:find(forth_name)
  return self.dict:find(forth_name)
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

function Compiler:def_word(alias, name, immediate)
  self.dict:def_word(alias, name, immediate)
end

function Compiler:exec_macro(item)
  local mod, fun = self.dict:find(item.token).lua_name:match("^(.-)%.(.+)$")
  if mod == "macros" and type(macros[fun]) == "function" then
    return macros[fun](self, item)
  else
    error("Unknown macro: " .. item.token .. " at line: " .. item.line_number)
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
      return ast.push(ast.identifier(item.token))
    end
    if word then -- Regular Forth word
      return ast.func_call(word.lua_name)
    end
    if interop.is_mixed_lua_expression(item.token) then
      -- Table lookup: math.pi or tbl.key or method call a:b a:b.c
      local parts = interop.explode(item.token)
      local name = parts[1]
      if self.env:has_var(name) or
              interop.resolve_lua_obj(name)
      then
        -- This can result multiple values, like img:getDimensions,
        -- a single value like tbl.key or str:upper, or nothing like img:draw
        -- TODO if only tbl, than use push instead of push many as it must be faster
        return ast.push_many(ast.identifier(interop.join(parts)))
      else
        error("Unkown variable: " .. name .. " at: " .. item.token)
      end
    end
    if interop.resolve_lua_obj(item.token) then
      -- Lua globals from _G, such as math, table, io
      return ast.push(ast.identifier(item.token))
    end
  end
  error("Unknown token: " .. item.token .. " kind: " .. item.kind)
end

function Compiler:compile(text)
  self:init(text)
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
      self.line_mapping:set_target_source(
        ast.forth_line_number,
        self.output.line_number)
    end
    if ast.name == "func_header" then
      local word = self.dict:find_by_lua_name(ast.func_name)
      word.line_number = self.output.line_number
    end
    self.output:append(code)
    self.output:new_line()
    if ast.name == "end_func" then
      local word = self.dict:find_by_lua_name(ast.func_name)
      word.code = string.gsub(
        self.output:text(word.line_number), "[\n\r]+$", "")
    end
  end
  return self.output
end

function Compiler:error_handler(err)
  local info = debug.getinfo(3, "lS")
  if info and info.source ~= self.chunk_name then
    info = debug.getinfo(4, "lS") -- if it was error/1
  end
  if info and info.currentline > 0 then
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
  end
  return err
end

function Compiler:eval(text, log_result)
  local code, err = self:compile_and_load(text, log_result)
  if err then
    self:error_handler(err) -- error during load
    return error(err)
  end
  local success, result = xpcall(code, function(e) self:error_handler(e) end)
  if success then
    return result
  else
    error(result) -- error during execute
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
