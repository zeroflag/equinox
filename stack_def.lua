local Stack = {}
local NIL = "__NIL__"

function Stack.new(name)
  local obj = {stack = {}, name = name}
  setmetatable(obj, {__index = Stack})
  return obj
end

function Stack.push(self, e)
  table.insert(self.stack, e ~= nil and e or NIL)
end

function Stack.push_many(self, ...)
  for i, item in ipairs({...}) do
    self:push(item)
  end
end

function Stack.pop(self)
  local item = table.remove(self.stack)
  if item == nil then
    error("Stack underflow: " .. self.name)
  end
  return item ~= NIL and item or nil
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

return Stack
