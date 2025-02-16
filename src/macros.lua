local aux = require("stack_aux")
local interop = require("interop")
local ast = require("ast")
local unpack = table.unpack or unpack

local macros = {}

function macros.add()
  return ast.push(ast.bin_op("+", ast.pop(), ast.pop()))
end

function macros.mul()
  return ast.push(ast.bin_op("*", ast.pop(), ast.pop()))
end

function macros.sub()
  return ast.push(ast.bin_op("-", ast.pop2nd(), ast.pop()))
end

function macros.div()
  return ast.push(ast.bin_op("/", ast.pop2nd(), ast.pop()))
end

function macros.mod()
  return ast.push(ast.bin_op("%", ast.pop2nd(), ast.pop()))
end

function macros.eq()
  return ast.push(ast.bin_op("==", ast.pop(), ast.pop()))
end

function macros.neq()
  return ast.push(ast.bin_op("~=", ast.pop(), ast.pop()))
end

function macros.lt()
  return ast.push(ast.bin_op(">", ast.pop2nd(), ast.pop()))
end

function macros.lte()
  return ast.push(ast.bin_op(">=", ast.pop2nd(), ast.pop()))
end

function macros.gt()
  return ast.push(ast.bin_op("<", ast.pop2nd(), ast.pop()))
end

function macros.gte()
  return ast.push(ast.bin_op("<=", ast.pop2nd(), ast.pop()))
end

function macros._not()
  return ast.push(ast.unary_op("not", ast.pop()))
end

function macros._and()
  return ast.stack_op("_and")
end

function macros._or()
  return ast.stack_op("_or")
end

function macros.concat()
  return ast.push(ast.bin_op("..", ast.pop2nd(), ast.pop()))
end

function macros.new_table()
  return ast.new_table()
end

function macros.table_size()
  return ast.push(ast.unary_op("#", ast.pop()))
end

function macros.table_at()
  return ast.push(ast.table_at(ast.pop2nd(), ast.pop()))
end

function macros.table_put()
  return ast.table_put(ast.pop3rd(), ast.pop2nd(), ast.pop())
end

function macros.depth()
  return ast.push(ast.stack_op("depth"))
end

function macros.adepth()
  return ast.push(ast.aux_op("depth"))
end

function macros.dup()
  return ast.stack_op("dup")
end

function macros.drop()
  return ast.pop()
end

function macros.over()
  return ast.stack_op("over")
end

function macros.nip()
  return ast.stack_op("nip")
end

function macros.dup2()
  return ast.stack_op("dup2")
end

function macros.mrot()
  return ast.stack_op("mrot")
end

function macros.tuck()
  return ast.stack_op("tuck")
end

function macros.rot()
  return ast.stack_op("rot")
end

function macros.swap()
  return ast.stack_op("swap")
end

function macros.to_aux()
  return ast.aux_push(ast.pop())
end

function macros.from_aux()
  return ast.push(ast.aux_op("pop"))
end

function macros.pick()
  return ast.push(ast.func_call("pick", ast.pop()))
end

function macros.roll()
  return ast.func_call("roll", ast.pop())
end

function macros.dot()
  return {
    ast.func_call("io.write", ast.func_call("tostring", ast.pop())),
    ast.func_call("io.write", ast.str(" "))
  }
end

function macros.cr()
  return ast.func_call("print")
end

function macros.def_alias(compiler, item)
  local forth_name = compiler:word()
  local alias = {}
  if not forth_name then
    compiler:err("Missing alias name", item)
  end

  repeat
    local exp = compiler:next_item()
    if exp then
      table.insert(alias, compiler:compile_token(exp))
    end
  until not exp
    or compiler:peek_chr() == "\n"
    or compiler:peek_chr() == "\r"

  if #alias == 0 then
    compiler:err("Missing alias body", item)
  end
  compiler:alias(alias, forth_name)
end

local function def_word(compiler, is_global, item)
  local forth_name = compiler:word()
  if not forth_name then
    compiler:err("Missing name for colon definition.", item)
  end
  local lua_name = interop.sanitize(forth_name)
  if select(2, forth_name:gsub("%:", "")) > 1 or
     select(2, forth_name:gsub("%.", "")) > 1
  then
    compiler:err("Name '" .. forth_name .. "' " ..
                 "can't contain multiple . or : characters.", item)
  end
  if interop.dot_or_colon_notation(forth_name) then -- method syntax
    local parts = interop.explode(forth_name)
    local obj = parts[1]
    local method = parts[3] -- parts[2] is expected to be . or :
    if not interop.is_valid_lua_identifier(method) then
      compiler:err("Name '" .. method .. "' " ..
                   "is not a valid name for dot or colon notation.", item)
    end
    if not compiler:has_var(obj) then
      compiler:warn("Unknown object: '" .. tostring(obj) .. "'" ..
          "in method definition: " .. forth_name, item)
    end
    if forth_name:find(":") then
      compiler:def_var("self")
    end
  elseif compiler:find(forth_name) then -- Regular Forth word
    -- emulate hyper static glob env for funcs but not for methods
    lua_name = lua_name .. "__s" .. compiler.state.sequence
    compiler.state.sequence = compiler.state.sequence + 1
  end
  if not interop.dot_or_colon_notation(forth_name) then
    compiler:def_word(forth_name, lua_name, false, true)
  end
  compiler:new_env("colon_" .. lua_name)
  local header = ast.func_header(lua_name, is_global)
  if compiler.state.last_word then
    compiler:err("Word definitions cannot be nested.", item)
  else
    compiler.state.last_word = header
  end
  return header
end

function macros.colon(compiler, item)
  return def_word(compiler, true, item)
end

function macros.local_colon(compiler, item)
  return def_word(compiler, false, item)
end

function macros.tick(compiler, item)
  local name = compiler:word()
  if not name then
    compiler:err("A word is required for '", item)
  end
  local word = compiler:find(name)
  if not word then
    compiler:err(name .. " is not found in dictionary", item)
  elseif word.immediate then
    compiler:err("' cannot be used on a macro: " .. name, item)
  elseif word.is_lua_alias then
    compiler:err("' cannot be used on an alias: " .. name, item)
  end
  return ast.push(ast.identifier(word.lua_name))
end

function macros.exec(compiler)
  return ast.func_call("pop()")
end

function macros.ret(compiler)
  return ast._return(ast.pop())
end

function macros.comment(compiler)
  repeat
    local ch = compiler:next_chr()
  until ")" == ch or "" == ch
end

function macros.single_line_comment(compiler)
  repeat
    local ch = compiler:next_chr()
  until "\n" == ch or "\r" == ch or "" == ch
  if ch == "\r" and compiler:peek_chr() == "\n" then
    compiler:next_chr()
  end
end

local function is_valid_exp(exp, compiler)
  local name = exp
  if interop.dot_or_colon_notation(exp) then
    name = interop.explode(exp)[1]
  end
  return compiler:valid_ref(name) or compiler:find(name)
end

function macros.arity_call_lua(compiler, item)
  local func  = compiler:word()
  if not is_valid_exp(func, compiler) then
    compiler:err("Unkown function or word: " .. func, item)
  end
  local numret = -1
  local arity = 0
  local token = compiler:word()
  if token ~= ")" then
    arity = tonumber(token)
    if not arity or arity < 0 then
      compiler:err("expected arity number, got '"
                   .. tostring(token) .. "'", item)
    end
    token = compiler:word()
    if token ~= ")" then
      numret = tonumber(token)
      if not numret or numret < -1 or numret > 1 then
        compiler:err("expected number of return values (0/1/-1), got '"
                     .. tostring(token) .. "'", item)
      end
      token = compiler:word()
      if token ~= ")" then
        compiler:err("expected closing ), got '"
                     .. tostring(token) .. "'", item)
      end
    end
  end
  local params = {}
  local stmts = {}
  if arity > 0 then
    for i = 1, arity do
      table.insert(params,
        ast.identifier(ast.gen_id("__p")))
    end
    for i = arity, 1, -1 do -- reverse parameter order
      table.insert(stmts,
        ast.init_local(params[i].id, ast.pop()))
    end
  end
  if numret == 0 then
    table.insert(stmts, ast.func_call(func, unpack(params)))
  elseif numret == 1 then
    table.insert(stmts, ast.push(
                   ast.func_call(func, unpack(params))))
  elseif numret == -1 then
    table.insert(stmts, ast.push_many(
                   ast.func_call(func, unpack(params))))
  else
    compiler:err("Invalid numret:" .. tostring(numret), item)
  end
  return stmts
end

function macros.var(compiler, item)
  local name = compiler:word()
  if name then
    return ast.def_local(compiler:def_var(name))
  else
    compiler:err("Missing variable name.", item)
  end
end

function macros.var_global(compiler, item)
  local name = compiler:word()
  if name then
    return ast.def_global(compiler:def_global(name))
  else
    compiler:err("Missing variable name.", item)
  end
end

local function valid_tbl_assignment(compiler, name)
  if interop.is_lua_prop_lookup(name) then
    local tbl = interop.table_name(name)
    return compiler:has_var(tbl)
      or interop.resolve_lua_obj(name)
  end
  return false
end

function macros.assignment(compiler, item)
  local name = compiler:word()
  if not name then
    compiler:err("Missing variable name.", item)
  end
  if name == "var" then
    -- declare and assign of a new var
    name = compiler:word()
    if not name then
      compiler:err("Missing variable name.", item)
    end
    return ast.init_local(compiler:def_var(name), ast.pop())
  elseif name == "global" then
    -- declare and assign of a new global
    name = compiler:word()
    if not name then
      compiler:err("Missing variable name.", item)
    end
    return ast.init_global(compiler:def_global(name), ast.pop())
  else
    -- assignment of existing var
    if compiler:has_var(name) then
      return ast.assignment(
        compiler:find_var(name).lua_name, ast.pop())
    elseif valid_tbl_assignment(compiler, name) then -- 123 -> tbl.x
      local parts = interop.explode(name)
      if compiler:has_var(parts[1]) then
        parts[1] = compiler:find_var(parts[1]).lua_name
        return ast.assignment(interop.join(parts), ast.pop())
      else
        return ast.assignment(name, ast.pop())
      end
    else
      compiler:err("Undeclared variable: " .. name, item)
    end
  end
end

function macros._if(compiler)
  compiler:new_env('IF')
  return ast._if(ast.pop())
end

function macros._else()
  return ast.keyword("else")
end

function macros._then(compiler, item)
  compiler:remove_env('IF', item)
  return ast.keyword("end")
end

function macros._begin(compiler)
  -- begin..until / begin..again / begin..while..repeat
  compiler:new_env('BEGIN_LOOP')
  return ast._while(ast.literal("boolean", "true"))
end

function macros._again(compiler, item)
  compiler:remove_env('BEGIN_LOOP', item)
  return ast.keyword("end")
end

function macros._repeat(compiler, item)
  compiler:remove_env('BEGIN_LOOP', item)
  return ast.keyword("end")
end

function macros._until(compiler, item)
  compiler:remove_env('BEGIN_LOOP', item)
  return {
    ast._if(ast.pop(), ast.keyword("break")),
    ast.keyword("end")
  }
end

function macros.block(compiler)
  compiler:new_env('BLOCK')
  return ast.keyword("do")
end

function macros._while()
  return ast._if(ast.unary_op("not", ast.pop()), ast.keyword("break"))
end

function macros._case(compiler) -- simulate goto with break, in pre lua5.2 since GOTO was not yet supported
  compiler:new_env('CASE')
  return ast.keyword("repeat")
end

function macros._of(compiler)
  compiler:new_env('OF')
  return {
    ast.stack_op("over"),
    ast._if(ast.bin_op("==", ast.pop(), ast.pop())),
    ast.pop() -- drop selector
  }
end

function macros._endof(compiler, item) -- GOTO endcase
  compiler:remove_env('OF', item)
  return { ast.keyword("break"), ast.keyword("end") }
end

function macros._endcase(compiler, item)
  compiler:remove_env('CASE', item)
  return ast._until(ast.literal("boolean", "true"))
end

function macros._exit()
  return ast._return(nil) -- exit from Forth word
end

function macros._do(compiler)
  local do_loop_vars = {"i", "j", "k"}
  local state = compiler.state
  local loop_var =
    do_loop_vars[((state.do_loop_nesting -1) % #do_loop_vars) +1]
  state.do_loop_nesting = state.do_loop_nesting + 1
  compiler:new_env('DO_LOOP')
  compiler:def_var(loop_var)
  return ast._for(
      loop_var,
      ast.pop(),
      ast.bin_op("-", ast.pop(), ast.literal("number", 1)),
      nil)
end

function macros._loop(compiler, item)
  compiler:remove_env('DO_LOOP', item)
  compiler.state.do_loop_nesting =
    compiler.state.do_loop_nesting - 1
  return ast.keyword("end")
end

function macros.for_ipairs(compiler, item)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  if not var_name1 or not var_name2 then
    compiler:err("ipairs needs two loop variables", item)
  end
  compiler:new_env('IPAIRS_LOOP')
  compiler:def_var(var_name1)
  compiler:def_var(var_name2)
  return ast._foreach(var_name1, var_name2, ast._ipairs(ast.pop()))
end

function macros.for_pairs(compiler, item)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  if not var_name1 or not var_name2 then
    compiler:err("pairs needs two loop variables", item)
  end
  compiler:new_env('PAIRS_LOOP')
  compiler:def_var(var_name1)
  compiler:def_var(var_name2)
  return ast._foreach(var_name1, var_name2, ast._pairs(ast.pop()))
end

function macros.for_each(compiler, item)
  local var_name = compiler:word()
  if not var_name then
    compiler:err("iter needs one loop variable", item)
  end
  compiler:new_env('ITER_LOOP')
  compiler:def_var(var_name)
  return ast._foreach(var_name, nil, ast.pop())
end

function macros._to(compiler, item)
  local loop_var = compiler:word()
  if not loop_var then
    compiler:err("to loop needs a loop variable.", item)
  end
  compiler:new_env('TO_LOOP')
  compiler:def_var(loop_var)
  return ast._for(loop_var, ast.pop2nd(), ast.pop(), nil)
end

function macros._step(compiler, item)
  local loop_var = compiler:word()
  if not loop_var then
    compiler:err("step loop needs a loop variable.", item)
  end
  compiler:new_env('STEP_LOOP')
  compiler:def_var(loop_var)
  return ast._for(loop_var, ast.pop3rd(), ast.pop2nd(), ast.pop(), nil)
end

function macros._end(compiler)
  compiler:remove_env() -- can belong to multiple
  return ast.keyword("end")
end

function macros.end_word(compiler, item)
  if not compiler.state.last_word then
    compiler:err("Unexpected semicolon", item)
  end
  local name = compiler.state.last_word.func_name
  macros.reveal(compiler, item)
  compiler.state.last_word = nil
  compiler:remove_env()
  return ast.end_func(name)
end

function macros.see(compiler, item)
  local name = compiler:word()
  if not name then
    compiler:err("See needs a word name", item)
  end
  local word = compiler:find(name)
  if not word then
    compiler:err(name .. " is not found in dictionary", item)
  elseif word.immediate then
    print("N/A. Macro (immediate word)")
  elseif word.is_lua_alias then
    print("N/A. Alias")
  else
    print(word.code)
  end
end

function macros.keyval(compiler)
  local name = compiler:word()
  return {
    ast.push(ast.str(name)),
    ast.push(ast.identifier(name))
  }
end

function macros.formal_params(compiler, item)
  if not compiler.state.last_word then
    compiler:err("Unexpected (:", item)
  end
  local func_header = compiler.state.last_word
  local param_name = compiler:word()
  while param_name ~= ":)" do
    compiler:def_var(param_name)
    table.insert(func_header.params, param_name)
    param_name = compiler:word()
  end
  return result
end

function macros.reveal(compiler, item)
  if not compiler.state.last_word then
    compiler:err("Reveal must be used within a word definition.", item)
  end
  compiler:reveal(compiler.state.last_word.func_name)
end

function macros.words(compiler)
  for i, each in ipairs(compiler:word_list()) do
    io.write(each .. " ")
  end
  print()
end

return macros
