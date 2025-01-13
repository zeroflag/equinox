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

local function parse_arity(arity)
  if arity and #arity > 0 then
    return tonumber(arity)
  else
    return 0
  end
end

function interop.parse_signature(signature)
  local name, arity = string.match(signature, "([^%/]+)%/(%d*)")
  if name then
    return {name=name, arity=parse_arity(arity), void=false}
  end
  local name, arity = string.match(signature, "([^%/]+)%!(%d*)")
  if name then
    return {name=name, arity=parse_arity(arity), void=true}
  end
  return nil
end

function interop.is_lua_prop_lookup(token)
  return string.match(token, ".+%..+") and
    not string.match(token, "([/!]%d*)$")
end

return interop
