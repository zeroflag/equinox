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
