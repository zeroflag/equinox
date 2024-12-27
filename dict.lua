local dict  = {}

function dict.defword(alias, name, immediate)
  dict[alias] = { ["name"] = name, imm = immediate, callable = true }
end

function dict.defvar(alias, name)
  dict[alias] = { ["name"] = name, callable = false }
end

function dict.find(name)
  return dict[name]
end

dict.defword("+", "ops.add", false)
dict.defword("-", "ops.sub", false)
dict.defword("*", "ops.mul", false)
dict.defword("/", "ops.div", false)
dict.defword(".", "ops.dot", false)
dict.defword("=", "ops.eq", false)
dict.defword("!=", "ops.neq", false)
dict.defword("<", "ops.lt", false)
dict.defword("<=", "ops.lte", false)
dict.defword(">", "ops.gt", false)
dict.defword(">=", "ops.gte", false)
dict.defword("swap", "ops.swap", false)
dict.defword("over", "ops.over", false)
dict.defword("rot", "ops.rot", false)
dict.defword("drop", "ops.drop", false)
dict.defword("dup", "ops.dup", false)
dict.defword("depth", "ops.depth", false)
dict.defword("not", "ops._not", false)
dict.defword("and", "ops._and", false)
dict.defword("or", "ops._or", false)
dict.defword("..", "ops.concat", false)
dict.defword(">a", "ops.to_aux", false)
dict.defword("a>", "ops.from_aux", false)
dict.defword("assert", "ops.assert", false)
dict.defword("if", "macros._if", true)
dict.defword("then", "macros._then", true)
dict.defword("else", "macros._else", true)
dict.defword("begin", "macros._begin", true)
dict.defword("until", "macros._until", true)
dict.defword("->", "macros.assignment", true)
dict.defword("var", "macros.var", true)
dict.defword("(", "macros.comment", true)
dict.defword("\\", "macros.single_line_comment", true)
dict.defword(":", "macros.colon", true)
dict.defword(";", "macros._end", true)

return dict
