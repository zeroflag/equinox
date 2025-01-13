local stack = require("stack")
local aux = require("aux")
local interop = require("interop")
local ast = require("ast")

local macros = {}
local sequence = 1

local function sanitize(str)
  str = str:gsub("-", "_mi_")
    :gsub("%+", "_pu_")
    :gsub("%%", "_pe_")
    :gsub("/", "_fs_")
    :gsub("\\", "_bs_")
    :gsub("~", "_ti_")
    :gsub("#", "_hs_")
    :gsub("%*", "_sr_")
    :gsub(";", "_sc_")
    :gsub("&", "_an_")
    :gsub("|", "_or_")
    :gsub("@", "_at_")
    :gsub("`", "_bt_")
    :gsub("=", "_eq_")
    :gsub("'", "_sq_")
    :gsub('"', "_dq_")
    :gsub("?", "_qe_")
    :gsub("!", "_ex_")
    :gsub(",", "_ca_")
    :gsub(":", "_cm_")
    :gsub("%{", "_c1_")
    :gsub("%}", "_c2_")
    :gsub("%[", "_b1_")
    :gsub("%]", "_b2_")
    :gsub("%(", "_p1_")
    :gsub("%(", "_p2_")
  if str:match("^%d+") then
    str = "_" .. str
  end
  if str:match("^%.") then
    str = "dot_" .. str:sub(2)
  end
  return str
end

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
  return ast.push(ast.func_call("stack:at", ast.pop()))
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

function macros.def_lua_alias(compiler)
  local lua_name = compiler:word()
  forth_alias = compiler:word()
  compiler:alias(lua_name, forth_alias)
end

local function def_word(compiler, is_global)
  compiler:new_env()
  local forth_name = compiler:word()
  local lua_name = sanitize(forth_name)
  if compiler:find(forth_name) then
    lua_name = lua_name .. "__s" .. sequence
  end
  sequence = sequence + 1
  compiler:def_word(forth_name, lua_name, false)
  local header = ast.func_header(lua_name, is_global)
  stack:push(header)
  return header
end

function macros.colon(compiler)
  return def_word(compiler, true)
end

function macros.local_colon(compiler)
  return def_word(compiler, false)
end

function macros.tick(compiler)
  local name = compiler:word()
  local word = compiler:find(name)
  if not word then
    error(name .. " is not found in dictionary")
  elseif word.immediate then
    error("' cannot be used on a macro: " .. name)
  end
  return ast.push(ast.identifier(word.lua_name))
end

function macros.exec(compiler)
  return ast.func_call("stack:pop()")
end

function macros.ret(compiler)
  return ast._return(ast.pop())
end

function macros.comment(compiler)
  repeat until ")" == compiler:next_chr()
end

function macros.single_line_comment(compiler)
  local ch
  repeat
    ch = compiler:next_chr()
  until "\n" == ch or "\r" == ch
  if ch == "\r" and compiler:peek_chr() == "\n" then
    compiler:next_chr()
  end
end

function macros.var(compiler)
  local name = compiler:word()
  compiler:def_var(name, name)
  return ast.def_local(name)
end

function macros.assignment(compiler)
  local name = compiler:word()
  if name == "var" then
    -- declare and assign of a new var
    name = compiler:word()
    compiler:def_var(name, name)
    return ast.init_local(name, ast.pop())
  else
    -- assignment of existing var
    return ast.assignment(name, ast.pop())
  end
end

function macros._if()
  return ast._if(ast.pop())
end

function macros._else()
  return ast.keyword("else")
end

function macros._begin(compiler)
  -- begin..until / begin..again / begin..while..repeat
  compiler:new_env('BEGIN_LOOP')
  return ast._while(ast.literal("boolean", "true"))
end

function macros._until(compiler)
  compiler:remove_env('BEGIN_LOOP')
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

function macros._case() -- simulate goto with break, in pre lua5.2 since GOTO was not yet supported
  return ast.keyword("repeat")
end

function macros._of()
  return {
    ast.stack_op("over"),
    ast._if(ast.bin_op("==", ast.pop(), ast.pop())),
    ast.pop() -- drop selector
  }
end

function macros._endof() -- GOTO endcase
  return { ast.keyword("break"), ast.keyword("end") }
end

function macros._endcase()
  return ast._until(ast.literal("boolean", "true"))
end

function macros._exit()
  return ast._return(nil) -- exit from Forth word
end

local do_loop_nesting = 0
local do_loop_vars = {"i", "j", "k"}

function macros._do(compiler)
  do_loop_nesting = do_loop_nesting + 1
  local loop_var = do_loop_vars[((do_loop_nesting -1) % #do_loop_vars) +1]
  compiler:new_env('DO_LOOP')
  compiler:def_var(loop_var, loop_var)
  return ast._for(
      loop_var,
      ast.pop(),
      ast.bin_op("-", ast.pop(), ast.literal("number", 1)),
      nil)
end

function macros._loop(compiler)
  compiler:remove_env('DO_LOOP')
  do_loop_nesting = do_loop_nesting - 1
  return ast.keyword("end")
end

function macros.for_ipairs(compiler)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  compiler:new_env('IPAIRS_LOOP')
  compiler:def_var(var_name1, var_name1)
  compiler:def_var(var_name2, var_name2)
  return ast._foreach(var_name1, var_name2, ast._ipairs(ast.pop()))
end

function macros.for_pairs(compiler)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  compiler:new_env('PAIRS_LOOP')
  compiler:def_var(var_name1, var_name1)
  compiler:def_var(var_name2, var_name2)
  return ast._foreach(var_name1, var_name2, ast._pairs(ast.pop()))
end

function macros._to(compiler)
  local loop_var = compiler:word()
  compiler:new_env('TO_LOOP')
  compiler:def_var(loop_var, loop_var)
  return ast._for(loop_var, ast.pop2nd(), ast.pop(), nil)
end

function macros._step(compiler)
  local loop_var = compiler:word()
  compiler:new_env('STEP_LOOP')
  compiler:def_var(loop_var, loop_var)
  return ast._for(loop_var, ast.pop3rd(), ast.pop2nd(), ast.pop(), nil)
end

function macros._then(compiler)
  return ast.keyword("end")
end

function macros._end(compiler)
  compiler:remove_env()
  return ast.keyword("end")
end

function macros.end_word(compiler)
  if stack:depth() == 0 or
     stack:tos().name ~= "func_header"
  then
    error("Unexpected semicolon") -- TODO line num
  end
  stack:pop()
  return macros._end(compiler)
end

function macros.keyval(compiler)
  local name = compiler:word()
  return {
    ast.push(ast.str(name)),
    ast.push(ast.identifier(name))
  }
end

function macros.formal_params(compiler)
  if stack:depth() == 0 or
     stack:tos().name ~= "func_header"
  then
    error("Unexpected (:") -- TODO line num
  end
  local func_header = stack:tos()
  local param_name = compiler:word()
  while param_name ~= ":)" do
    compiler:def_var(param_name, param_name)
    table.insert(func_header.params, param_name)
    param_name = compiler:word()
  end
  return result
end

function macros.words(compiler)
  for i, each in ipairs(compiler:word_list()) do
    io.write(each .. " ")
  end
  print()
end

return macros
