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

function interop.is_lua_prop_lookup(token)
  return string.match(token, ".+%..+@$")
end

return interop
