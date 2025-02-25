local stack = require("stack")

assert(depth() == 0)

push("a")
assert(depth() == 1)
push("b")
assert(depth() == 2)

assert(tos() == "b")
assert(tos2() == "a")

assert(pop() == "b")
assert(depth() == 1)
assert(tos() == "a")

assert(pop() == "a")
assert(depth() == 0)

push("xx")
push("p1")
push("p2")
push("p3")

assert(depth() == 4)

local p3, p2, p1 = pop(), pop(), pop()

assert(p1 == "p1")
assert(p2 == "p2")
assert(p3 == "p3")

assert(pop() == "xx")
assert(depth() == 0)

push(nil)
assert(depth() == 1)
assert(nil == pop())
assert(depth() == 0)

push(1)
push(2)
push(3)
assert(depth() == 3)
assert(pop2nd() == 2)
assert(depth() == 2)
assert(pop() == 3)
assert(pop() == 1)

assert(depth() == 0)

push(1)
push(2)
push(3)
push(4)
assert(depth() == 4)
assert(pop3rd() == 2)
assert(depth() == 3)
assert(pop() == 4)
assert(pop() == 3)
assert(pop() == 1)

assert(depth() == 0)

push_many(1, 2, 3)
assert(depth() == 3)
assert(pop() == 3)
assert(pop() == 2)
assert(pop() == 1)

push_many(nil, 2)
assert(depth() == 2)
assert(pop() == 2)
assert(pop() == nil)

function multi_return()
  return 4, 5
end

push_many(multi_return())
assert(depth() == 2)
assert(pop() == 5)
assert(pop() == 4)

push(1)
push(2)
push(3)

assert(3 == pick(0))
assert(2 == pick(1))
assert(1 == pick(2))

assert(pop() == 3)
assert(pop() == 2)
assert(pop() == 1)

assert(depth() == 0)
