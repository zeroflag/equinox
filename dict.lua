local dict = {}

function dict.define(alias, name, immediate)
  dict[alias] = { ["name"] = name, imm = immediate }
end

dict.define("+", "ops.add", false)
dict.define("-", "ops.sub", false)
dict.define("*", "ops.mul", false)
dict.define("/", "ops.div", false)
dict.define(".", "ops.dot", false)
dict.define("=", "ops.eq", false)
dict.define("!=", "ops.neq", false)
dict.define("<", "ops.lt", false)
dict.define("<=", "ops.lte", false)
dict.define(">", "ops.gt", false)
dict.define(">=", "ops.gte", false)
dict.define("swap", "ops.swap", false)
dict.define("over", "ops.over", false)
dict.define("drop", "ops.drop", false)
dict.define("dup", "ops.dup", false)
dict.define("if", "macros._if", true)
dict.define("then", "macros._then", true)
dict.define("else", "macros._else", true)
dict.define("begin", "macros._begin", true)
dict.define("until", "macros._until", true)
dict.define(":", "macros.colon", true)
dict.define(";", "macros._end", true)

return dict
