local Stack = {}
local NIL = "__NIL__"

function Stack.new(name)
  local obj = {stack = {nil,nil,nil,nil,nil,nil,nil,nil}, name = name}
  setmetatable(obj, {__index = Stack})
  return obj
end

function Stack.push(self, e)
  self.stack[#self.stack + 1] = (e ~= nil and e or NIL)
end

function Stack.push_many(self, ...)
  local args = {...}
  local stack = self.stack
  for i = 1, #args do
    stack[#stack + 1] = (args[i] ~= nil and args[i] or NIL)
  end
end

function Stack.pop(self)
  local item = table.remove(self.stack)
  if not item then
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
