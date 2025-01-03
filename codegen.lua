local CodeGen = {}

function CodeGen.new()
  local obj = {}
  setmetatable(obj, {__index = CodeGen})
  return obj
end

function CodeGen.gen(self, ast)
  if "stack_op" == ast.name then
    return "stack:" .. ast.op .. "()"
  end
  if "aux_op" == ast.name then
    return "aux:" .. ast.op .. "()"
  end
  if "push" == ast.name then
    return string.format("stack:push(%s)", self:gen(ast.item))
  end
  if "push_many" == ast.name then
    return string.format("stack:push_many(%s)", self:gen(ast.func_call))
  end
  if "push_aux" == ast.name then
    return string.format("aux:push(%s)", self:gen(ast.item))
  end
  if "unary_op" == ast.name then
    return string.format("%s %s", ast.op, self:gen(ast.p1))
  end
  if "bin_op" == ast.name then
    return string.format(
      "%s %s %s", self:gen(ast.p1), ast.op, self:gen(ast.p2))
  end
  if "local" == ast.name then
    return "local " .. ast.var
  end
  if "init_local" == ast.name then
    return "local " .. ast.var .. "=" .. self:gen(ast.val)
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
    return string.format("while(%s)do", self:gen(ast.cond))
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
      return string.format(
        "for %s,%s in %s do",
        ast.loop_var1, ast.loop_var2, self:gen(ast.iterable))
  end
  if "pairs" == ast.name then
    return string.format("pairs(%s)", self:gen(ast.iterable))
  end
  if "ipairs" == ast.name then
    return string.format("ipairs(%s)", self:gen(ast.iterable))
  end
  if "if" == ast.name then
    if ast.body then
      return "if " .. self:gen(ast.cond) .. " then " .. self:gen(ast.body) .. " end"
    else
      return "if " .. self:gen(ast.cond) .. " then"
    end
  end
  if "keyword" == ast.name then return ast.keyword end
  if "identifier" == ast.name then return ast.id end
  if "return" == ast.name then return "do return end" end
  if "table_new" == ast.name then return "stack:push({})" end
  if "table_at" == ast.name then
    return string.format("stack:push(%s[%s])",
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
  if "code_seq" == ast.name then
    local result = ""
    for i, c in ipairs(ast.code) do
      result = result .. self:gen(c)
      if i < #ast.code then
        result = result .. "\n"
      end
    end
    return result
  end
  if "func_header" == ast.name then
    if ast.arity == 0 then
      return "function " .. ast.func_name .. "()"
    else
      local result = "function " .. ast.func_name .. "("
      for i = 1, ast.arity do
        result = result .. "__a" .. i
        if i < ast.arity then result = result .. "," end
      end
      result = result .. ")\n"
      for i = 1, ast.arity do
        result = result .. "stack:push(__a" .. i .. ")\n"
      end
      return result
    end
  end
  error("Unknown AST: " .. tostring(ast) ..
        " with name: " .. tostring(ast.name))
end

return CodeGen
