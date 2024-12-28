local Stack = require("stack_def")
local stack = require("stack")
local aux = require("aux")
local ops = {}

function ops.dup()
  stack:push(stack:tos())
end

function ops.add()
  stack:push(stack:pop() + stack:pop())
end

function ops.mul()
  stack:push(stack:pop() * stack:pop())
end

function ops.div()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(b / a)
end

function ops.sub()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(b - a)
end

function ops.depth()
  stack:push(stack:depth())
end

function ops.adepth()
  stack:push(aux:depth())
end

function ops.swap()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(a)
  stack:push(b)
end

function ops.over()
  stack:push(stack:tos2())
end

function ops.rot()
  local c = stack:pop()
  local b = stack:pop()
  local a = stack:pop()
  stack:push(b)
  stack:push(c)
  stack:push(a)
end

function ops.drop()
  stack:pop()
end

function ops.eq()
  stack:push(stack:pop() == stack:pop())
end

function ops.neq()
  stack:push(stack:pop() ~= stack:pop())
end

function ops.lt()
  stack:push(stack:pop() > stack:pop())
end

function ops.lte()
  stack:push(stack:pop() >= stack:pop())
end

function ops.gt()
  stack:push(stack:pop() < stack:pop())
end

function ops.gte()
  stack:push(stack:pop() <= stack:pop())
end

function ops._not()
  stack:push(not stack:pop())
end

function ops._and()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(a and b)
end

function ops._or()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(a or b)
end

function ops.concat()
  local a = stack:pop()
  local b = stack:pop()
  stack:push(b .. a)
end

function ops.dot()
  io.write(tostring(stack:pop()))
  io.write(" ")
end

function ops.lit(literal)
  stack:push(literal)
end

function ops.to_aux()
  aux:push(stack:pop())
end

function ops.from_aux()
  stack:push(aux:pop())
end

function ops.new_table()
  stack:push({})
end

function ops.table_size()
  stack:push(#stack:pop())
end

function ops.table_at()
  local n = stack:pop()
  local t = stack:pop()
  stack:push(t[n])
end

function ops:table_put()
  local value = stack:pop()
  local key = stack:pop()
  local tbl = stack:pop()
  tbl[key] = value
end

function ops:shields_up()
  Stack.safety(true)
end

function ops:shields_down()
  Stack.safety(false)
end

return ops
