local sp = 1
local stack = {}
for i = 1, 128 do stack[i] = nil end

function stack.push(e)
  stack[sp] = e
  sp = sp + 1
end

function stack.pop()
  sp = sp - 1
  return stack[sp]
end

function stack.tos()
  return stack[sp-1]
end

function stack.tos2()
  return stack[sp-2]
end

function stack.depth()
  return sp - 1
end

return stack
