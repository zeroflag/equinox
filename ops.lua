local stack = require("stack")
local ops = {}

function ops.dup()
  stack.push(stack.tos())
end

function ops.add()
  stack.push(stack.pop() + stack.pop())
end

function ops.mul()
  stack.push(stack.pop() * stack.pop())
end

function ops.div()
  local a = stack.pop()
  local b = stack.pop()
  stack.push(b / a)
end

function ops.sub()
  local a = stack.pop()
  local b = stack.pop()
  stack.push(b - a)
end

function ops.swap()
  local a = stack.pop()
  local b = stack.pop()
  stack.push(a)
  stack.push(b)
end

function ops.over()
  stack.push(stack.tos2())
end

function ops.drop()
  stack.pop()
end

function ops.eq()
  stack.push(stack.pop() == stack.pop())
end

function ops.neq()
  stack.push(stack.pop() ~= stack.pop())
end

function ops.lt()
  stack.push(stack.pop() > stack.pop())
end

function ops.lte()
  stack.push(stack.pop() >= stack.pop())
end

function ops.gt()
  stack.push(stack.pop() < stack.pop())
end

function ops.gte()
  stack.push(stack.pop() <= stack.pop())
end

function ops.dot()
  print(stack.pop())
end

function ops.stor()
  -- TODO
end

function ops.fetch()
  -- TODO
end

function ops.lit(literal)
  stack.push(literal)
end

return ops
