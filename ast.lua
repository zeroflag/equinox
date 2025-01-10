local ast = {}

local id_counter = 1

function ast.gen_id(prefix)
  id_counter = id_counter + 1
  return prefix .. id_counter
end

function ast.func_header(func_name, arity, void, global)
  return {
    name = "func_header",
    func_name = func_name,
    arity = arity,
    void = void,
    global = global
  }
end

function ast.func_call(func_name, ...)
  return {
    name = "func_call",
    func_name = func_name,
    args = {...}
  }
end

function ast.pop()
  return {name = "stack_consume", op  = "pop"}
end

function ast.pop2nd()
  return {name = "stack_consume", op  = "pop2nd"}
end

function ast.pop3rd()
  return {name = "stack_consume", op  = "pop3rd"}
end

function ast.stack_peek(operation)
  return {name = "stack_peek", op = operation}
end

function ast.stack_op(operation)
  return {name = "stack_op", op = operation}
end

function ast.aux_op(operation)
  return {name = "aux_op", op = operation}
end

function ast.push(item)
  return {name  = "push", item = item}
end

function ast.push_many(func_call)
  return {name  = "push_many", func_call = func_call}
end

function ast.aux_push(item)
  return {name  = "push_aux", item = item}
end

function ast._while(cond)
  return {
    name = "while",
    cond = cond
  }
end

function ast._until(cond)
  return {
    name = "until",
    cond = cond
  }
end

function ast.literal(kind, value)
  return {
    name = "literal",
    kind = kind,
    value = value
  }
end

function ast.str(val)
  return ast.literal("string", val)
end

function ast.bin_op(operator, param1, param2)
  return {
    name = "bin_op",
    op = operator,
    p1 = param1,
    p2 = param2
  }
end

function ast.unary_op(operator, operand)
  return {name = "unary_op", op = operator, exp = operand}
end

function ast.assignment(var, exp)
  return {name = "assignment", var  = var, exp  = exp}
end

function ast.init_local(var, exp)
  return {name = "init_local", var = var, exp = exp}
end

function ast._if(cond, body)
  return {name = "if", exp = cond, body = body}
end

function ast.def_local(var)
  return {name = "local", var = var}
end

function ast.new_table()
  return {name = "table_new"}
end

function ast.table_at(tbl, key)
  return {name = "table_at", key = key, tbl = tbl}
end

function ast.table_put(tbl, key, value)
  return {
    name = "table_put",
    tbl = tbl,
    key = key,
    value = value
  }
end

function ast.keyword(keyword)
  return {name = "keyword", keyword = keyword}
end

function ast.identifier(id)
  return {name = "identifier", id = id}
end

function ast._return()
  return {name = "return"}
end

function ast._for(loop_var, start, stop, step)
  return {
    name = "for",
    loop_var = loop_var,
    start = start,
    stop = stop,
    step = step
  }
end

function ast._foreach(loop_var1, loop_var2, iterable)
  return {
    name = "for_each",
    loop_var1 = loop_var1,
    loop_var2 = loop_var2,
    iterable = iterable
  }
end

function ast._ipairs(iterable)
  return {name = "ipairs", iterable = iterable}
end

function ast._pairs(iterable)
  return {name = "pairs", iterable = iterable}
end

return ast
