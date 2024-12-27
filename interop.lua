local interop = {}

function interop.resolve_lua_func(name)
  local func = _G
  for part in name:gmatch("[^%.]+") do
    func = func[part]
    if func == nil then return nil end
  end
  if type(func) == "function" then
    return func
  else
    return nil
  end
end

function parse(signature)
  if string.find(signature, "/") then
    local name, arity = string.match(signature, "([^%/]+)(%/%d+)")
    return name, tonumber(arity:sub(2))
  else
    return string.match(signature, "([^%/]+)")
  end
end

function interop.resolve_lua_func_with_arity(signature)
  local name, arity = parse(signature)
  local func = interop.resolve_lua_func(name)
  local vararg = false
  if not func then return nil end
  if not arity then
    local info = debug.getinfo(func, "u") -- Doesn't work with C funcs or older than Lua5.2
    arity, vararg = info.nparams, info.isvararg
  end
  return { name = name, arity = arity, vararg = vararg }
end

return interop
