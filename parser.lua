local interop = require("interop")

local Parser = {}

local function lines_of(input)
  local lines = {}
  for line in input:gmatch("([^\r\n]*)\r?\n?") do
    table.insert(lines, line)
  end
  return lines
end

function Parser.new(source, dict)
  local obj = {index = 1,
               line_number = 1,
               source = source,
               lines = lines_of(source),
               dict = dict}
  setmetatable(obj, {__index = Parser})
  return obj
end

function Parser:parse_all()
  local result = {}
  local item = self:next_item()
  while item do
    table.insert(result, item)
    item = self:next_item()
  end
  return result
end

local function is_quote(chr)
  return chr:match('"')
end

local function is_escape(chr)
  return chr:match("\\")
end

local function lua_func_call(token, res)
  return {
    token = token,
    kind = "lua_func_call",
    name = res.name,
    arity = res.arity,
    vararg = res.vararg,
    void = res.void
  }
end

local function lua_method_call(token, res)
  return {
    token = token,
    kind = "lua_method_call",
    name = res.name,
    arity = res.arity,
    vararg = res.vararg,
    void = res.void
  }
end

local function lua_table_lookup(token, resolved)
  return {token = token, kind = "lua_table_lookup", resolved = resolved}
end

local function lua_array_lookup(token, resolved)
  return {token = token, kind = "lua_array_lookup", resolved = resolved}
end

local function literal(token, subtype)
  return {token = token, kind = "literal", subtype = subtype}
end

local function unknown(token)
  return {token = token, kind = "unknown"}
end

local function is_whitespace(chr)
  return chr:match("%s")
end

function Parser:check_line_ending(chr)
end

function Parser:next_item()
  local token = ""
  local begin_str = false
  local stop = false
  local kind = "word"
  while not self:ended() and not stop do
    local chr = self:read_chr()
    if is_quote(chr) then
      if begin_str then
        stop = true
      else
        kind = "string"
        begin_str = true
      end
      token = token .. chr
    elseif begin_str
      and is_escape(chr)
      and is_quote(self:peek_chr()) then
      token = token .. chr .. self:read_chr() -- consume \"
    elseif is_whitespace(chr) and not begin_str then -- TODO how does this handle multiline strings
      if #token > 0 then
        self.index = self.index -1 -- don't consume next WS as it breaks single line comment
        stop = true
      else
        self:update_line_number(chr)
      end
    else
      token = token .. chr
    end
  end
  if token == "" then
    return nil
  end
  if token:match("^&.+") then kind = "symbol" end
  local result = self:parse_word(token, kind)
  result.line_number = self.line_number -- TODO comments breaks line number as they consume the input
  return result
end

function Parser:update_line_number(chr)
  if chr == '\r' then
    if self:peek_chr() == '\n' then self:read_chr() end
    self.line_number = self.line_number +1
  elseif chr == '\n' then
    self.line_number = self.line_number +1
  end
end

function Parser:next_chr()
  local chr = self:read_chr()
  self:update_line_number(chr)
  return chr
end

function Parser:read_chr()
  local chr = self:peek_chr()
  self.index = self.index + 1
  return chr
end

function Parser:peek_chr()
  return self.source:sub(self.index, self.index)
end

function Parser:parse_word(token, kind)
  local word = self.dict:find(token)
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
    if lua_obj or self.dict:find(token:match("^[^.]+")) then
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

function Parser:ended()
  return self.index > #self.source
end

return Parser
