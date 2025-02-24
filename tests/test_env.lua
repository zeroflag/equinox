local Env = require("env")

local root = Env:new(nil, "root")

local child1 = Env:new(root, "child1")
local child2 = Env:new(root, "child2")

local child2_child = Env:new(child2, "child2_child")

--[[
  root
 /   \
c1    c2
        \
         c2c
]]--

root:def_var("rv1", "rv1")
child1:def_var("c1v", "c1v")
child2:def_var("c2v", "c2v")
child2_child:def_var("c2c", "c2c")

assert(root:has_var("rv1"))
assert(child1:has_var("rv1"))
assert(child2:has_var("rv1"))
assert(child2_child:has_var("rv1"))

assert(not root:has_var("c1v"))
assert(child1:has_var("c1v"))
assert(not child2:has_var("c1v"))
assert(not child2_child:has_var("c1v"))

assert(not root:has_var("c2v"))
assert(not child1:has_var("c2v"))
assert(child2:has_var("c2v"))
assert(child2_child:has_var("c2v"))

assert(not root:has_var("c2c"))
assert(not child1:has_var("c2c"))
assert(not child2:has_var("c2c"))
assert(child2_child:has_var("c2c"))

assert(#root:var_names() == 1)
assert(#child1:var_names() == 2)
assert(#child2:var_names() == 2)
assert(#child2_child:var_names() == 3)
