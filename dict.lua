local interop = require("interop")

local Dict = {}

function Dict:new()
  local obj = {words = {}}
  setmetatable(obj, {__index = self})
  obj:init()
  return obj
end

local function entry(forth_name, lua_name, immediate, is_lua_alias)
  return {
    forth_name = forth_name,
    lua_name = lua_name,
    immediate = immediate,
    is_lua_alias = is_lua_alias,
    line_number = nil
  }
end

local function is_valid_lua_identifier(name)
  local keywords = {
      ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true,
      ["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["goto"] = true,
      ["if"] = true, ["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true,
      ["or"] = true, ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
      ["until"] = true, ["while"] = true }
  if keywords[name] then
      return false
  end
  return name:match("^[a-zA-Z_][a-zA-Z0-9_]*$") ~= nil
end

function Dict:def_word(forth_name, lua_name, immediate)
  table.insert(self.words, entry(forth_name, lua_name, immediate, false))
end

function Dict:def_macro(forth_name, lua_name)
  self:def_word(forth_name, lua_name, true)
end

function Dict:def_lua_alias(lua_name, forth_name)
  table.insert(self.words, entry(forth_name, lua_name, immediate, true))
end

function Dict:find(name)
  return self:find_by(
    function (item)
      return item.forth_name == name
    end)
end

function Dict:find_by_lua_name(name)
  return self:find_by(
    function (item)
      return item.lua_name == name
    end)
end

function Dict:find_by(pred)
  for i = #self.words, 1, -1 do
    local each = self.words[i]
    if pred(each) then
      return each
    end
  end
  return nil
end

function Dict:word_list()
  local result, seen = {}, {}
  for i, each in ipairs(self.words) do
    if not seen[each.forth_name] then
      if each.is_lua_alias or
         each.immediate or
         interop.resolve_lua_func(each.lua_name)
      then
        table.insert(result, each.forth_name)
      end
      seen[each.forth_name] = true
    end
  end
  return result
end

function Dict:init()
  self:def_macro("+", "macros.add")
  self:def_macro("-", "macros.sub")
  self:def_macro("*", "macros.mul")
  self:def_macro("/", "macros.div")
  self:def_macro("%", "macros.mod")
  self:def_macro(".", "macros.dot")
  self:def_macro("cr", "macros.cr")
  self:def_macro("=", "macros.eq")
  self:def_macro("!=", "macros.neq")
  self:def_macro(">", "macros.lt")
  self:def_macro(">=", "macros.lte")
  self:def_macro("<", "macros.gt")
  self:def_macro("<=", "macros.gte")
  self:def_macro("swap", "macros.swap")
  self:def_macro("over", "macros.over")
  self:def_macro("rot", "macros.rot")
  self:def_macro("-rot", "macros.mrot")
  self:def_macro("nip", "macros.nip")
  self:def_macro("drop", "macros.drop")
  self:def_macro("dup", "macros.dup")
  self:def_macro("2dup", "macros.dup2")
  self:def_macro("tuck", "macros.tuck")
  self:def_macro("depth", "macros.depth")
  self:def_macro("pick", "macros.pick")
  self:def_macro("adepth", "macros.adepth")
  self:def_macro("not", "macros._not")
  self:def_macro("and", "macros._and")
  self:def_macro("or", "macros._or")
  self:def_macro("..", "macros.concat")
  self:def_macro(">a", "macros.to_aux")
  self:def_macro("a>", "macros.from_aux")
  self:def_macro("{}", "macros.new_table")
  self:def_macro("[]", "macros.new_table")
  self:def_macro("size", "macros.table_size")
  self:def_macro("at", "macros.table_at")
  self:def_macro("@", "macros.table_at")
  self:def_macro("put", "macros.table_put")
  self:def_macro("!", "macros.table_put")
  self:def_macro("words", "macros.words")
  self:def_macro("exit", "macros._exit")
  self:def_macro("return", "macros.ret")
  self:def_macro("if", "macros._if")
  self:def_macro("then", "macros._then")
  self:def_macro("else", "macros._else")
  self:def_macro("begin", "macros._begin")
  self:def_macro("until", "macros._until")
  self:def_macro("while", "macros._while")
  self:def_macro("repeat", "macros._end")
  self:def_macro("again", "macros._end")
  self:def_macro("case", "macros._case")
  self:def_macro("of", "macros._of")
  self:def_macro("endof", "macros._endof")
  self:def_macro("endcase", "macros._endcase")
  self:def_macro("do", "macros._do")
  self:def_macro("loop", "macros._loop")
  self:def_macro("ipairs:", "macros.for_ipairs")
  self:def_macro("pairs:", "macros.for_pairs")
  self:def_macro("to:", "macros._to")
  self:def_macro("step:", "macros._step")
  self:def_macro("#(", "macros.arity_call_lua")
  self:def_macro("->", "macros.assignment")
  self:def_macro("var", "macros.var")
  self:def_macro("global", "macros.var_global")
  self:def_macro("(", "macros.comment")
  self:def_macro("\\", "macros.single_line_comment")
  self:def_macro("alias:", "macros.def_alias")
  self:def_macro(":", "macros.colon")
  self:def_macro("::", "macros.local_colon")
  self:def_macro(";", "macros.end_word")
  self:def_macro("exec", "macros.exec")
  self:def_macro("'", "macros.tick")
  self:def_macro("$", "macros.keyval")
  self:def_macro("(:", "macros.formal_params")
  self:def_macro("block", "macros.block")
  self:def_macro("end", "macros._end")
  self:def_macro("see", "macros.see")
end

return Dict
