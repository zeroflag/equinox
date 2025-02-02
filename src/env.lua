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
  local lua_name = interop.sanitize(name)
  self:def_var_unsafe(name, lua_name)
  return lua_name
end

function Env:has_var(forth_name)
  return self:find_var(forth_name) ~= nil
end

function Env:find_var(forth_name)
  for i, each in ipairs(self.vars) do
    if each.forth_name == forth_name then
      return each
    end
  end
  return self.parent and self.parent:find_var(forth_name)
end

function Env:var_names()
  local result
  if not self.parent then
    result = {}
  else
    result = self.parent:var_names()
  end
  for _, each in ipairs(self.vars) do
    table.insert(result, each.forth_name)
  end
  return result
end

return Env
