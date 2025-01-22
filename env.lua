local Env = {}

function Env:new(parent, name)
  local obj = {parent = parent,
               name = name,
               vars = {}}
  setmetatable(obj, {__index = self})
  return obj
end

local function is_valid_lua_identifier(name)
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

function Env:def_var_unsafe(forth_name, lua_name)
  table.insert(self.vars, {forth_name = forth_name,
                           lua_name = lua_name})
end

function Env:def_var(name)
  if is_valid_lua_identifier(name) then
    self:def_var_unsafe(name, name)
  else
    error(name .. " is not a valid variable name. Avoid reserved keywords and special characters.")
  end
end

function Env:has_var(forth_name)
  for i, each in ipairs(self.vars) do
    if each.forth_name == forth_name then
      return true
    end
  end
  return self.parent and self.parent:has_var(forth_name)
end

return Env
