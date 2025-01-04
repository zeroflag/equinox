local Stack = {}
local NIL = "__NIL__"

function Stack.new(name)
  local obj = {stack = {nil,nil,nil,nil,nil,nil,nil,nil}, name = name}
  setmetatable(obj, {__index = Stack})
  return obj
end

function Stack:push(e)
  self.stack[#self.stack + 1] = (e ~= nil and e or NIL)
end

function Stack:push_many(...)
  local args = {...}
  local stack = self.stack
  for i = 1, #args do
    stack[#stack + 1] = (args[i] ~= nil and args[i] or NIL)
  end
end

function Stack:pop()
  local item = table.remove(self.stack)
  if not item then
    error("Stack underflow: " .. self.name)
  end
  return item ~= NIL and item or nil
end

function Stack:pop2nd()
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  local item = table.remove(self.stack, n - 1)
  return item ~= NIL and item or nil
end

function Stack:pop3rd()
  local n = #self.stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local item = table.remove(self.stack, n - 2)
  return item ~= NIL and item or nil
end

function Stack:swap()
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  self.stack[n], self.stack[n - 1] = self.stack[n - 1], self.stack[n]
end

function Stack:rot()
  local n = #self.stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local new_top = self.stack[n-2]
  table.remove(self.stack, n - 2)
  self.stack[n] = new_top
end

function Stack:mrot()
  local n = #self.stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local temp = table.remove(self.stack, n)
  table.insert(self.stack, n - 2, temp)
end

function Stack:over()
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  self.stack[n + 1] = self.stack[n - 1]
end

function Stack:tuck()
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  table.insert(self.stack, n - 1, self.stack[n])
end

function Stack:nip()
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  table.remove(self.stack, n - 1)
end

function Stack:dup()
  local n = #self.stack
  if n < 1 then
    error("Stack underflow: " .. self.name)
  end
  self.stack[n + 1] = self.stack[n]
end

function Stack:dup2()
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  local tos1 = self.stack[n]
  local tos2 = self.stack[n - 1]
  self.stack[n + 1] = tos2
  self.stack[n + 2] = tos1
end

function Stack:tos()
  return self.stack[#self.stack]
end

function Stack:tos2()
  return self.stack[#self.stack - 1]
end

function Stack:_and()
  local a, b = self:pop(), self:pop()
  self:push(a and b)
end

function Stack:_or()
  local a, b = self:pop(), self:pop()
  self:push(a or b)
end

function Stack:depth()
  return #self.stack
end

return Stack
