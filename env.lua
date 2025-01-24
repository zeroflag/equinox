local interop = require("interop")

local Env = {}

function Env:new(parent, name)
  local obj = {parent = parent,
               name = name,
               vars = {}}
  setmetatable(obj, {__index = self})
  return obj
end

function Env:def_var_unsafe(forth_name, lua_name)
  table.insert(self.vars, {forth_name = forth_name,
                           lua_name = lua_name})
end

function Env:def_var(name)
  if interop.is_valid_lua_identifier(name) then
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
