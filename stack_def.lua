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

function Stack.swap(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  self.stack[n], self.stack[n - 1] = self.stack[n - 1], self.stack[n]
end

function Stack.rot(self)
  local n = #self.stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local new_top = self.stack[n-2]
  table.remove(self.stack, n - 2)
  self.stack[n] = new_top
end

function Stack.mrot(self)
  local n = #self.stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local temp = table.remove(self.stack, n)
  table.insert(self.stack, n - 2, temp)
end

function Stack.over(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  self.stack[n + 1] = self.stack[n - 1]
end

function Stack.tuck(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  table.insert(self.stack, n - 1, self.stack[n])
end

function Stack.nip(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  table.remove(self.stack, n - 1)
end

function Stack.dup(self)
  local n = #self.stack
  if n < 1 then
    error("Stack underflow: " .. self.name)
  end
  self.stack[n + 1] = self.stack[n]
end

function Stack.dup2(self)
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  local tos1 = self.stack[n]
  local tos2 = self.stack[n - 1]
  self.stack[n + 1] = tos2
  self.stack[n + 2] = tos1
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
