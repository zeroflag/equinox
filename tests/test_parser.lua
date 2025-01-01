local dict = require("dict")
local json = require("tests/json")
local Input = require("input")
local Parser = require("parser")

function parse(text)
  local parser = Parser.new(Input.new(text), dict)
  return parser:parse()
end

function assert_table(t1, t2)
  local j1 = to_json_str(t1)
  local j2 = to_json_str(t2)
  assert(j1 == j2, "\nT1=" .. j1 .. "\nT2=" .. j2)
end

assert_table({} , parse(""))

assert_table({{token = "1", kind = "literal", subtype = "number"}}, parse("1"))
assert_table({{token = "dup", kind = "macro"}}, parse("dup"))

assert_table(
  {{token = '"test string"', kind = "literal", subtype = "string"}},
  parse('"test string"'))

assert_table(
  {{token = ":sym", kind = "literal", subtype = "symbol"}},
  parse(':sym'))

assert_table({
    { token = "1", kind = "literal", subtype = "number" },
    { token = "2", kind = "literal", subtype = "number" },
    { token = "+", kind = "macro" }
  }, parse("1 2 +"))

assert_table(
  {{token = "math.min/2", kind = "lua_func_call", name = "math.min", arity = 2, vararg = false, void = false}},
  parse("math.min/2"))

assert_table(
  {{token = "math.min!2", kind = "lua_func_call", name = "math.min", arity = 2, vararg = false, void = true}},
  parse("math.min!2"))

assert_table(
  {{token = "math.min", kind = "lua_func_call", name = "math.min", arity = 0, vararg = false, void = false}},
  parse("math.min"))

assert_table(
  {{token = "obj:method/3", kind = "lua_method_call", name = "obj:method", arity = 3, vararg = false, void = false}},
  parse("obj:method/3"))

assert_table(
  {{token = "obj:method!3", kind = "lua_method_call", name = "obj:method", arity = 3, vararg = false, void = true}},
  parse("obj:method!3"))

assert_table(
  {{token = "obj:method", kind = "lua_method_call", name = "obj:method", arity = 0, vararg = false, void = false}},
  parse("obj:method"))

dict.def_var("tbl1", "tbl1")
assert_table(
  {{token = "tbl1.key1", kind = "lua_table_lookup"}},
  parse("tbl1.key1"))

assert_table(
  {{token = "math.pi", kind = "lua_table_lookup"}},
  parse("math.pi"))

dict.def_word("myword", "myword")
assert_table(
  {{token = "myword", kind = "word"}},
  parse("myword"))
