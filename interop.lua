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

function interop.sanitize(str)
  str = str:gsub("-", "_mi_")
    :gsub("%+", "_pu_")
    :gsub("%%", "_pe_")
    :gsub("/", "_fs_")
    :gsub("\\", "_bs_")
    :gsub("~", "_ti_")
    :gsub("#", "_hs_")
    :gsub("%*", "_sr_")
    :gsub(";", "_sc_")
    :gsub("&", "_an_")
    :gsub("|", "_or_")
    :gsub("@", "_at_")
    :gsub("`", "_bt_")
    :gsub("=", "_eq_")
    :gsub("'", "_sq_")
    :gsub('"', "_dq_")
    :gsub("?", "_qe_")
    :gsub("!", "_ex_")
    :gsub(",", "_ca_")
    :gsub("%{", "_c1_")
    :gsub("%}", "_c2_")
    :gsub("%[", "_b1_")
    :gsub("%]", "_b2_")
    :gsub("%(", "_p1_")
    :gsub("%(", "_p2_")
  if str:match("^%d+") then
    str = "_" .. str
  end
  -- . and : are only allowed at the beginning or end
  if str:match("^%.") then str = "dot_" .. str:sub(2) end
  if str:match("^%:") then str = "col_" .. str:sub(2) end
  if str:match("%.$") then str = str:sub(1, #str -1) .. "_dot" end
  if str:match("%:$") then str = str:sub(1, #str -1) .. "_col" end
  return str
end

return interop
