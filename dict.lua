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

function dict.def_lua_alias(lua_name, forth_name)
  table.insert(words, entry(forth_name, lua_name, immediate, false, true))
end

function dict.defvar(forth_name, lua_name)
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

dict.def_word("+", "ops.add", false)
dict.def_word("-", "ops.sub", false)
dict.def_word("*", "ops.mul", false)
dict.def_word("/", "ops.div", false)
dict.def_word("%", "ops.mod", false)
dict.def_word(".", "ops.dot", false)
dict.def_word("=", "ops.eq", false)
dict.def_word("!=", "ops.neq", false)
dict.def_word("<", "ops.lt", false)
dict.def_word("<=", "ops.lte", false)
dict.def_word(">", "ops.gt", false)
dict.def_word(">=", "ops.gte", false)
dict.def_word("swap", "ops.swap", false)
dict.def_word("over", "ops.over", false)
dict.def_word("rot", "ops.rot", false)
dict.def_word("drop", "ops.drop", false)
dict.def_word("dup", "ops.dup", false)
dict.def_word("depth", "ops.depth", false)
dict.def_word("adepth", "ops.adepth", false)
dict.def_word("not", "ops._not", false)
dict.def_word("and", "ops._and", false)
dict.def_word("or", "ops._or", false)
dict.def_word("..", "ops.concat", false)
dict.def_word(">a", "ops.to_aux", false)
dict.def_word("a>", "ops.from_aux", false)
dict.def_word("assert", "ops.assert", false)
dict.def_word("shields-up", "ops.shields_up", false)
dict.def_word("shields-down", "ops.shields_down", false)
dict.def_word("<table>", "ops.new_table", false)
dict.def_word("size", "ops.table_size", false)
dict.def_word("at", "ops.table_at", false)
dict.def_word("put", "ops.table_put", false)
dict.def_word("words", "macros.words", true)
dict.def_word("if", "macros._if", true)
dict.def_word("then", "macros._then", true)
dict.def_word("else", "macros._else", true)
dict.def_word("begin", "macros._begin", true)
dict.def_word("until", "macros._until", true)
dict.def_word("do", "macros._do", true)
dict.def_word("loop", "macros._loop", true)
dict.def_word("i", "macros._i", true)
dict.def_word("j", "macros._j", true)
dict.def_word("->", "macros.assignment", true)
dict.def_word("var", "macros.var", true)
dict.def_word("(", "macros.comment", true)
dict.def_word("\\", "macros.single_line_comment", true)
dict.def_word("lua-alias:", "macros.def_lua_alias", true)
dict.def_word(":", "macros.colon", true)
dict.def_word(";", "macros._end", true)

return dict
