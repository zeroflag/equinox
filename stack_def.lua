local Stack = {}

function Stack.new(size)
  local obj = {stack = {}, sp = 1}
  -- TODO check size, overflow / underflow
  setmetatable(obj, {__index = Stack})
  return obj
end

function Stack.push(self, e)
  self.stack[self.sp] = e
  self.sp = self.sp + 1
end

function Stack.pop(self)
  self.sp = self.sp - 1
  return self.stack[self.sp]
end

function Stack.tos(self)
  return self.stack[self.sp-1]
end

function Stack.tos2(self)
  return self.stack[self.sp-2]
end

function Stack.depth(self)
  return self.sp - 1
end

return Stack
