local CodeGen = {}

function CodeGen:new()
  local obj = {}
  setmetatable(obj, {__index = self})
  return obj
end

local function lit_bin_op(ast)
  return ast.name == "bin_op"
    and ast.p1.name == "literal"
    and ast.p2.name == "literal"
end

local function lit_unary_op(ast)
  return ast.name == "unary_op" and ast.exp.name == "literal"
end

local function inline_push(exp)
  return "stack[#stack +1] = " .. exp
end

function CodeGen:gen(ast)
  if "stack_op" == ast.name
    or "stack_consume" == ast.name
    or "stack_peek" == ast.name
  then
    return ast.op .. "()"
  end
  if "aux_op" == ast.name then
    return "a" .. ast.op .. "()"
  end
  if "push" == ast.name then
    if ast.exp.name == "literal" or
       lit_bin_op(ast.exp) or
       lit_unary_op(ast.exp)
    then
      return inline_push(self:gen(ast.exp)) -- bypass NIL check
    else
      return string.format("push(%s)", self:gen(ast.exp))
    end
  end
  if "push_many" == ast.name then
    return string.format("push_many(%s)", self:gen(ast.func_call))
  end
  if "push_aux" == ast.name then
    return string.format("apush(%s)", self:gen(ast.exp))
  end
  if "unary_op" == ast.name then
    return string.format("%s %s", ast.op, self:gen(ast.exp))
  end
  if "bin_op" == ast.name then
    return string.format(
      "(%s %s %s)", self:gen(ast.p1), ast.op, self:gen(ast.p2))
  end
  if "local" == ast.name then
    return "local " .. ast.var
  end
  if "global" == ast.name then
    return ast.var .. "=nil"
  end
  if "init_local" == ast.name then
    return "local " .. ast.var .. "=" .. self:gen(ast.exp)
  end
  if "init_global" == ast.name then
    return ast.var .. "=" .. self:gen(ast.exp)
  end
  if "assignment" == ast.name then
    return ast.var .. " = " .. self:gen(ast.exp)
  end
  if "literal" == ast.name and "boolean" == ast.kind then
    return ast.value
  end
  if "literal" == ast.name and "string" == ast.kind then
    return '"' .. ast.value .. '"'
  end
  if "literal" == ast.name and "number" == ast.kind then
    return ast.value
  end
  if "while" == ast.name then
    return string.format("while (%s) do", self:gen(ast.cond))
  end
  if "until" == ast.name then
    return string.format("until %s", self:gen(ast.cond))
  end
  if "for" == ast.name and not ast.step then
      return string.format(
        "for %s=%s,%s do",
        ast.loop_var, self:gen(ast.start), self:gen(ast.stop))
  end
  if "for" == ast.name and ast.step then
      return string.format(
        "for %s=%s,%s,%s do",
        ast.loop_var,
        self:gen(ast.start),
        self:gen(ast.stop),
        self:gen(ast.step))
  end
  if "for_each" == ast.name then
    if ast.loop_var1 and ast.loop_var2 then
      return string.format(
        "for %s,%s in %s do",
        ast.loop_var1, ast.loop_var2, self:gen(ast.iterable))
    else
      return string.format(
        "for %s in %s do",
        ast.loop_var1, self:gen(ast.iterable))
    end
  end
  if "pairs" == ast.name then
    return string.format("pairs(%s)", self:gen(ast.iterable))
  end
  if "ipairs" == ast.name then
    return string.format("ipairs(%s)", self:gen(ast.iterable))
  end
  if "if" == ast.name then
    if ast.body then
      return "if " .. self:gen(ast.exp) .. " then " .. self:gen(ast.body) .. " end"
    else
      return "if " .. self:gen(ast.exp) .. " then"
    end
  end
  if "return" == ast.name then
    if ast.arg then
      return "return " .. self:gen(ast.arg)
    else
      return "do return end"
    end
  end
  if "keyword" == ast.name then return ast.keyword end
  if "identifier" == ast.name then return ast.id end
  if "table_new" == ast.name then return inline_push("{}") end
  if "table_at" == ast.name then
    return string.format("%s[%s]",
                         self:gen(ast.tbl), self:gen(ast.key))
  end
  if "table_put" == ast.name then
    return string.format(
      "%s[%s]=%s",
      self:gen(ast.tbl), self:gen(ast.key), self:gen(ast.value))
  end
  if "func_call" == ast.name then
    local params = ""
    for i, p in ipairs(ast.args) do
      params = params .. self:gen(p)
      if i < #ast.args then
        params = params .. ","
      end
    end
    return string.format("%s(%s)", ast.func_name, params)
  end
  if "func_header" == ast.name then
    local prefix = ""
    if not ast.global then prefix = "local " end
    local result = string.format("%sfunction %s(", prefix, ast.func_name)
    for i, p in ipairs(ast.params) do
      result = result .. p
      if i < #ast.params then result = result .. "," end
    end
    return result .. ")"
  end
  if "end_func" == ast.name then
    return "end"
  end
  error("Unknown AST: " .. tostring(ast) ..
        " with name: " .. tostring(ast.name))
end

return CodeGen
