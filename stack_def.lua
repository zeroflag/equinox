local err = require("err")

local Stack = {}

function Stack.new(name)
  local obj = {stack = {}, name = name}
  setmetatable(obj, {__index = Stack})
  return obj
end

function Stack.push(self, e)
  table.insert(self.stack, e)
end

function Stack.pop_safe(self)
  local item = table.remove(self.stack)
  if item == nil then
    err.abort("Stack underflow: " .. self.name)
  end
  return item
end

function Stack.pop_unsafe(self)
  return table.remove(self.stack)
end

function Stack.tos(self)
  return self.stack[#self.stack]
end

function Stack.tos2(self)
  return self.stack[#self.stack - 1]
end

function Stack.depth(self)
  return #self.stack
end

function Stack.safety(safe)
  if safe then
    Stack.pop = Stack.pop_safe
  else
    Stack.pop = Stack.pop_unsafe
  end
end

Stack.safety(true)

return Stack
