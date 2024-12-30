local words = {}
local dict  = { words = words }

function entry(forth_name, lua_name, immediate, callable, is_lua_alias)
  return {
    forth_name = forth_name,
    lua_name = lua_name,
    immediate = immediate,
    callable = callable,
    is_lua_alias = is_lua_alias
  }
end

function dict.def_word(forth_name, lua_name, immediate)
  table.insert(words, entry(forth_name, lua_name, immediate, true, false))
end

function dict.def_macro(forth_name, lua_name)
  dict.def_word(forth_name, lua_name, true)
end

function dict.def_lua_alias(lua_name, forth_name)
  table.insert(words, entry(forth_name, lua_name, immediate, false, true))
end

function dict.def_var(forth_name, lua_name)
  table.insert(words, entry(forth_name, lua_name, immediate, false, false))
end

function dict.find(forth_name)
  for i = #words, 1, -1 do
    local each = words[i]
    if each.forth_name == forth_name then
      return each
    end
  end
  return nil
end

function dict.word_list()
  local result = {}
  for i, each in ipairs(words) do
    table.insert(result, each.forth_name)
  end
  return result
end

dict.def_macro("+", "macros.add")
dict.def_macro("-", "macros.sub")
dict.def_macro("*", "macros.mul")
dict.def_macro("/", "macros.div")
dict.def_macro("%", "macros.mod")
dict.def_macro(".", "macros.dot")
dict.def_macro("=", "macros.eq")
dict.def_macro("!=", "macros.neq")
dict.def_macro("<", "macros.lt")
dict.def_macro("<=", "macros.lte")
dict.def_macro(">", "macros.gt")
dict.def_macro(">=", "macros.gte")
dict.def_macro("swap", "macros.swap")
dict.def_macro("over", "macros.over")
dict.def_macro("rot", "macros.rot")
dict.def_macro("drop", "macros.drop")
dict.def_macro("dup", "macros.dup")
dict.def_macro("depth", "macros.depth")
dict.def_macro("adepth", "macros.adepth")
dict.def_macro("not", "macros._not")
dict.def_macro("and", "macros._and")
dict.def_macro("or", "macros._or")
dict.def_macro("..", "macros.concat")
dict.def_macro(">a", "macros.to_aux")
dict.def_macro("a>", "macros.from_aux")
dict.def_macro("<table>", "macros.new_table")
dict.def_macro("size", "macros.table_size")
dict.def_macro("at", "macros.table_at")
dict.def_macro("put", "macros.table_put")
dict.def_macro("words", "macros.words")
dict.def_macro("exit", "macros._exit")
dict.def_macro("if", "macros._if")
dict.def_macro("then", "macros._then")
dict.def_macro("else", "macros._else")
dict.def_macro("begin", "macros._begin")
dict.def_macro("until", "macros._until")
dict.def_macro("while", "macros._while")
dict.def_macro("repeat", "macros._repeat")
dict.def_macro("again", "macros._repeat") -- same as repeat
dict.def_macro("do", "macros._do")
dict.def_macro("loop", "macros._loop")
dict.def_macro("i", "macros._i")
dict.def_macro("j", "macros._j")
dict.def_macro("->", "macros.assignment")
dict.def_macro("var", "macros.var")
dict.def_macro("(", "macros.comment")
dict.def_macro("\\", "macros.single_line_comment")
dict.def_macro("lua-alias:", "macros.def_lua_alias")
dict.def_macro(":", "macros.colon")
dict.def_macro(";", "macros._end")

return dict
