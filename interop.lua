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

function interop.table_name(token)
  return string.match(token, "^[^.]+")
end

function interop.explode(token)
  local result = {}
  for part, sep in token:gmatch("([^:%.]+)([:%.]?)") do
    table.insert(result, part)
    if sep ~= "" then
      table.insert(result, sep)
    end
  end
  return result
end

function interop.join(parts)
  local exp = ""
  for i, each in ipairs(parts) do
    exp = exp .. each
    if each ~= ":" and
        each ~= "." and
        parts[i-1] == ":"
    then
      exp = exp .. "()"
    end
  end
  return exp
end

function interop.is_mixed_lua_expression(token)
  return string.match(token, ".+[.:].+") and
    not string.match(token, "([/~]%d*)$")
end

function interop.is_lua_prop_lookup(token)
  return string.match(token, ".+%..+") and
    not string.match(token, "([/~]%d*)$")
end

return interop
