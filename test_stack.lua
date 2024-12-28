local Stack = require("stack_def")
local stack = Stack.new("test")

assert(stack:depth() == 0)

stack:push("a")
stack:push("b")

assert(stack:tos() == "b")
assert(stack:tos2() == "a")

assert(stack:depth() == 2)

assert(stack:pop() == "b")
assert(stack:pop() == "a")

assert(stack:depth() == 0)

stack:push("xx")
stack:push("p1")
stack:push("p2")
stack:push("p3")

assert(stack:depth() == 4)

local p3, p2, p1 = stack:pop(), stack:pop(), stack:pop()

assert(p1 == "p1")
assert(p2 == "p2")
assert(p3 == "p3")

assert(stack:pop() == "xx")
assert(stack:depth() == 0)

stack:push(nil)
assert(stack:depth() == 1)
assert(nil == stack:pop())
assert(stack:depth() == 0)
