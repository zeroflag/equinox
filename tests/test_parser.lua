local Dict = require("dict")
local json = require("tests/json")
local Parser = require("parser")

local dict = Dict.new()

function parse(text)
  local parser = Parser.new(text, dict)
  return parser:parse_all()
end

function assert_table(t1, t2)
  local j1 = to_json_str(t1)
  local j2 = to_json_str(t2)
  assert(j1 == j2, "\nT1=" .. j1 .. "\nT2=" .. j2)
end

assert_table({} , parse(""))

assert_table({{token = "1", kind = "literal", subtype = "number", line_number=1}}, parse("1"))
assert_table({{token = "dup", kind = "macro", line_number=1}}, parse("dup"))

assert_table(
  {{token = '"test string"', kind = "literal", subtype = "string", line_number=1}},
  parse('"test string"'))

assert_table(
  {{token = "&sym", kind = "literal", subtype = "symbol", line_number=1}},
  parse('&sym'))

assert_table(
  {{token = "math.min/2", kind = "lua_func_call", name = "math.min", arity = 2, vararg = false, void = false, line_number=1}},
  parse("math.min/2"))

assert_table(
  {{token = "math.min!2", kind = "lua_func_call", name = "math.min", arity = 2, vararg = false, void = true, line_number=1}},
  parse("math.min!2"))

assert_table(
  {{token = "math.min", kind = "lua_func_call", name = "math.min", arity = 0, vararg = false, void = false, line_number=1}},
  parse("math.min"))

assert_table(
  {{token = "obj:method/3", kind = "lua_method_call", name = "obj:method", arity = 3, vararg = false, void = false, line_number=1}},
  parse("obj:method/3"))

assert_table(
  {{token = "obj:method!3", kind = "lua_method_call", name = "obj:method", arity = 3, vararg = false, void = true, line_number=1}},
  parse("obj:method!3"))

assert_table(
  {{token = "obj:method", kind = "lua_method_call", name = "obj:method", arity = 0, vararg = false, void = false, line_number=1}},
  parse("obj:method"))

assert_table(
  {{token = "tbl1.key1", kind = "lua_table_lookup", resolved = false, line_number=1}},
  parse("tbl1.key1"))

dict:def_var("tbl1", "tbl1")

assert_table(
  {{token = "tbl1.key1", kind = "lua_table_lookup", resolved = true, line_number=1}},
  parse("tbl1.key1"))

assert_table(
  {{token = "math.pi", kind = "lua_table_lookup", resolved = true, line_number=1}},
  parse("math.pi"))

dict:def_word("myword", "myword")
assert_table(
  {{token = "myword", kind = "word", line_number=1}},
  parse("myword"))

assert_table({
    { token = "1", kind = "literal", subtype = "number", line_number=1},
    { token = "2", kind = "literal", subtype = "number",  line_number=1},
    { token = "+", kind = "macro", line_number=1 }
  }, parse("1 2 +"))

assert_table({
    { token = ":", kind = "macro", line_number=1 },
    { token = "double", kind = "unknown", line_number=1 },
    { token = "dup", kind = "macro", line_number=1 },
    { token = "+", kind = "macro", line_number=1 },
    { token = ";", kind = "macro", line_number=1 }
  }, parse(": double dup + ;"))

-- line number tests
assert_table({
    { token = "1", kind = "literal", subtype = "number", line_number=1},
    { token = "2", kind = "literal", subtype = "number",  line_number=2},
    { token = "+", kind = "macro", line_number=3 }
  }, parse("1\n2\n+"))

assert_table({
    { token = "1", kind = "literal", subtype = "number", line_number=1},
    { token = "2", kind = "literal", subtype = "number",  line_number=2},
    { token = "+", kind = "macro", line_number=3 }
  }, parse("1\n2\n+\n"))

assert_table({
    { token = "123", kind = "literal", subtype = "number", line_number=1},
    { token = "456", kind = "literal", subtype = "number",  line_number=1},
    { token = "678", kind = "literal", subtype = "number",  line_number=2},
  }, parse("123 456\n678\n"))

assert_table({
    { token = "123", kind = "literal", subtype = "number", line_number=3},
    { token = "456", kind = "literal", subtype = "number",  line_number=3},
    { token = "678", kind = "literal", subtype = "number",  line_number=6},
  }, parse("\n\n123 456\n\n\n678"))

assert_table({
    { token = '"a\nb c"', kind = "literal", subtype = "string", line_number=3},
    { token = '"d e f"', kind = "literal", subtype = "string",  line_number=3},
    { token = "678", kind = "literal", subtype = "number",  line_number=6},
  }, parse("\n\n \"a\nb c\" \"d e f\" \n\n\n678"))
