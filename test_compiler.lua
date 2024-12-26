local compiler = require("compiler")

compiler.trace = true
compiler:eval_file("lib.eqx")

function assert_tos(result, code)
  local stack = compiler:eval(code)
  assert(stack.depth() == 1,
         "'" .. code .. "' depth: " .. stack.depth())
  assert(stack.tos() == result,
         "'" .. code .. "' " .. tostring(stack.tos())
         .. " <> " .. tostring(result))
  stack.pop()
end

-- arithmetics - add
assert_tos(3, "1 2 +")
assert_tos(33, "0 33 +")
assert_tos(-6, "-2 -4 +")
assert_tos(-17, "-21 4 +")
assert_tos(140, "145 -5 +")
assert_tos(5.8, "3.3 2.5 +")
-- arithmetics - sub
assert_tos(1, "2 1 -")
assert_tos(-33, "0 33 -")
assert_tos(2, "-2 -4 -")
assert_tos(-25, "-21 4 -")
assert_tos(150, "145 -5 -")
assert_tos(10, "11.5 1.5 -")
-- arithmetics - mul
assert_tos(6, "2 3 *")
assert_tos(0, "0 33 *")
assert_tos(8, "-2 -4 *")
assert_tos(-300, "100 -3 *")
assert_tos(10, "2.5 4 *")
assert_tos(6.25, "2.5 2.5 *")
-- arithmetics - div
assert_tos(5, "10 2 /")
assert_tos(0.2, "2 10 /")
assert_tos(2, "-4 -2 /")
assert_tos(-2, "6 -3 /")
assert_tos(2.5, "10 4 /")
assert_tos(1, "2.5 2.5 /")
-- arithmetics - eq
assert_tos(true, "5 5 =")
assert_tos(false, "6 5 =")
assert_tos(true, "-6 -6 =")
assert_tos(false, "6 -6 =")
-- arithmetics - jeq
assert_tos(false, "5 5 !=")
assert_tos(true, "6 5 !=")
assert_tos(false, "-6 -6 !=")
assert_tos(true, "6 -6 !=")
-- arithmetics - lt
assert_tos(false, "5 5 <")
assert_tos(false, "6 5 <")
assert_tos(false, "-6 -6 <")
assert_tos(false, "6 -6 <")
assert_tos(true, "3 5 <")
assert_tos(true, "-1 5 <")
assert_tos(true, "-6 -2 <")
-- arithmetics - gt
assert_tos(false, "5 5 >")
assert_tos(true, "6 5 >")
assert_tos(false, "-6 -6 >")
assert_tos(true, "6 -6 >")
assert_tos(false, "3 5 >")
assert_tos(false, "-1 5 >")
assert_tos(false, "-6 -2 >")
-- arithmetics - lte
assert_tos(true, "5 5 <=")
assert_tos(false, "6 5 <=")
assert_tos(true, "-6 -6 <=")
assert_tos(false, "6 -6 <=")
assert_tos(true, "3 5 <=")
assert_tos(true, "-1 5 <=")
assert_tos(true, "-6 -2 <=")
-- arithmetics - gte
assert_tos(true, "5 5 >=")
assert_tos(true, "6 5 >=")
assert_tos(true, "-6 -6 >=")
assert_tos(true, "6 -6 >=")
assert_tos(false, "3 5 >=")
assert_tos(false, "-1 5 >=")
assert_tos(false, "-6 -2 >=")

-- stack - dup
assert_tos(10, "5 5 +")
-- stack - swap
assert_tos(3, "7 10 swap -")
-- stack - over
assert_tos(2, "1 2 over - +")

-- control if
assert_tos(8, "1 2 < if 8 then")
assert_tos(4, "1 2 > if 8 else 4 then")

-- control begin until
assert_tos(2048, "2 10 begin 1 - swap 2 * swap dup 0 = until drop")

-- def :
assert_tos(42, ": tst 42 ; tst")
assert_tos(6, ": dbl dup + ; 3 dbl")

compiler:eval(": min ( n n -- n ) 2dup < if drop else nip then ;")
assert_tos(4, "4 6 min")
assert_tos(2, "5 2 min")

-- max
compiler:eval(": max ( n n -- n ) 2dup < if nip else drop then ;")
assert_tos(6, "4 6 max")
assert_tos(5, "5 2 max")

assert_tos(5, [[
( 1 2 +
 1 1 *
 3 4 + )
 3 2 +
( this is a comment )
]])

-- var local
assert_tos(22, [[
  local v1 local v2
  10 -> v1 12 -> v2
  v1 v2 +
]])

-- var local
assert_tos(-3, [[
  local v1 local v2
  10 -> v1 v1 -> v2
  3 v2 + -> v2 ( 13 = v2 )
  v1 v2 - ( 10 13 - )
]])

-- var global
assert_tos(12, [[
  3 -> v1
  4 -> v2
  v1 v2 *
]])

assert_tos(4, [["asdf" string.len/1]])
assert_tos(9, [["asdf jkle" string.len/1]])
assert_tos(10, [["asdf jkle " string.len/1]])
assert_tos(10, [[" asdf jkle" string.len/1]])
assert_tos(11, [[" asdf jkle " string.len/1]])
assert_tos(0, [["" string.len/1]])
assert_tos(1, [[" " string.len/1]])
assert_tos(2, [["  " string.len/1]])
assert_tos(14, [["  asdf  jkle  " string.len/1]])

assert_tos(256, [[
  8 2 math.pow/2
]])

assert_tos(502, [[
  502 1002 math.min/2
]])
assert_tos(1002, [[
  502 1002 math.max/2
]])

assert_tos(502, [[
  502 1002 math.min/2
]])

local status, result = pcall(
  function()
    return compiler:eval("1 2 math.min")
  end)
assert(not status)
