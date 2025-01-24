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

function interop.is_lua_prop_lookup(token)
  return token:sub(2, #token -1):find("[.]")
end

function interop.dot_or_colon_notation(token)
  return token:sub(2, #token -1):find("[.:]")
end

function interop.is_valid_lua_identifier(name)
  local keywords = {
      ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true,
      ["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["goto"] = true,
      ["if"] = true, ["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true,
      ["or"] = true, ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
      ["until"] = true, ["while"] = true }
  if keywords[name] then
      return false
  end
  return name:match("^[a-zA-Z_][a-zA-Z0-9_]*$") ~= nil
end

return interop
