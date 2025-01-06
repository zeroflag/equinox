local Stack = {}
local NIL = {} -- nil cannot be stored in table, use this placeholder

function Stack.new(name)
  local obj = {stack = {nil,nil,nil,nil,nil,nil,nil,nil},
               name = name}
  setmetatable(obj, {__index = Stack})
  return obj
end

function Stack:push(e)
  self.stack[#self.stack + 1] = (e ~= nil and e or NIL)
end

function Stack:push_many(...)
  local args = {...}
  local stack = self.stack
  local n = #stack
  for i = 1, #args do
    stack[n + i] = (args[i] ~= nil and args[i] or NIL)
  end
end

function Stack:pop()
  local stack = self.stack
  local size = #stack
  if size == 0 then
    error("Stack underflow: " .. self.name)
  end
  local item = stack[size]
  stack[size] = nil
  return item ~= NIL and item or nil
end

function Stack:pop2nd()
  local stack = self.stack
  local n = #stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  local item = stack[n - 1]
  stack[n -1] = stack[n]
  stack[n] = nil
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
  local stack = self.stack
  local n = #stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  stack[n], stack[n - 1] = stack[n - 1], stack[n]
end

function Stack:rot()
  local stack = self.stack
  local n = #stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local new_top = stack[n -2]
  table.remove(stack, n - 2)
  stack[n] = new_top
end

function Stack:mrot()
  local stack = self.stack
  local n = #stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local temp = stack[n]
  stack[n] = nil
  table.insert(stack, n - 2, temp)
end

function Stack:over()
  local stack = self.stack
  local n = #stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  stack[n + 1] = stack[n - 1]
end

function Stack:tuck()
  local n = #self.stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  table.insert(self.stack, n - 1, self.stack[n])
end

function Stack:nip()
  local stack = self.stack
  local n = #stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  stack[n - 1] = stack[n]
  stack[n] = nil
end

function Stack:dup()
  local stack = self.stack
  local n = #stack
  if n < 1 then
    error("Stack underflow: " .. self.name)
  end
  stack[n + 1] = stack[n]
end

function Stack:dup2()
  local stack = self.stack
  local n = #stack
  if n < 2 then
    error("Stack underflow: " .. self.name)
  end
  local tos1 = stack[n]
  local tos2 = stack[n - 1]
  stack[n + 1] = tos2
  stack[n + 2] = tos1
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
