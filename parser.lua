local interop = require("interop")

local Parser = {}

function Parser.new(input, dict)
  local obj = {input = input, dict = dict}
  setmetatable(obj, {__index = Parser})
  return obj
end

function Parser.parse(self)
  local result = {}
  local token, kind = self.input:parse()
  while token ~= "" do
    local word_def = self.dict.find(token)
    if kind == "word"
      and word_def
      and word_def.immediate
    then
      table.insert(result, {token = token, kind = "macro"})
    else
      table.insert(result, self:parse_token(token, kind))
    end
    token, kind = self.input:parse()
  end
  return result
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

function lua_table_lookup(token)
  return {token = token, kind = "lua_table_lookup"}
end

function literal(token, subtype)
  return {token = token, kind = "literal", subtype = subtype}
end

function Parser.parse_token(self, token, kind)
  if kind == "string" then
    return literal(token, "string")
  end
  if kind == "symbol" then
    return literal(token, "symbol")
  end
  local word = self.dict.find(token)
  if word then
    if word.is_lua_alias then
      -- Known lua alias
      local res = interop.resolve_lua_func_with_arity(word.lua_name)
      return lua_func_call(token, res)
    else
      -- Forth word
      return {token = token, kind = "word"}
    end
  else
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
      -- Lua call such as math.max/2
      return lua_func_call(token, res)
    end
    if interop.is_lua_prop_lookup(token) then
      -- Table lookup
      local lua_obj = interop.resolve_lua_obj(token)
      -- best effort to check if it's valid lookup
      if lua_obj or self.dict.find(token:match("^[^.]+")) then
        return lua_table_lookup(token)
      else
        error("Unknown table lookup: " .. token)
      end
    else
      error("Word not found: '" .. token .. "'")
    end
  end
end

return Parser
