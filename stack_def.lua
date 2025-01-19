local Stack = {}
local NIL = {} -- nil cannot be stored in table, use this placeholder

function Stack:new(name)
  local obj = {stack = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil},
               name = name}
  setmetatable(obj, {__index = self})
  return obj
end

function Stack:push(e)
  if e ~= nil then
    self.stack[#self.stack + 1] = e
  else
    self.stack[#self.stack + 1] = NIL
  end
end

function Stack:push_many(...)
  local args = {...}
  local stack = self.stack
  local n = #stack
  for i = 1, #args do
    if args[i] ~= nil then
      stack[n + i] = args[i]
    else
      stack[n + i] = NIL
    end
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
  if item ~= NIL then return item else return nil end
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
  if item ~= NIL then return item else return nil end
end

function Stack:pop3rd()
  local n = #self.stack
  if n < 3 then
    error("Stack underflow: " .. self.name)
  end
  local item = table.remove(self.stack, n - 2)
  if item ~= NIL then return item else return nil end
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
  local item = self.stack[#self.stack]
  if item == nil then
    error("Stack underflow: " .. self.name)
  end
  if item ~= NIL then return item else return nil end
end

function Stack:tos2()
  local item = self.stack[#self.stack - 1]
  if item == nil then
    error("Stack underflow: " .. self.name)
  end
  if item ~= NIL then return item else return nil end
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

function Stack:at(index)
  local item = self.stack[#self.stack - index]
  if item == nil then
    error("Stack underflow: " .. self.name)
  end
  if item ~= NIL then return item else return nil end
end

return Stack
