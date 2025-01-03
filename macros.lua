local stack = require("stack")
local aux = require("aux")
local interop = require("interop")
local ast = require("ast")

-- TODO remove all compiler params

local macros = {}

local id_counter = 1

function gen_id(prefix)
  id_counter = id_counter + 1
  return prefix .. id_counter
end

function sanitize(str)
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
  return ast.push(ast.bin_op(">", ast.pop(), ast.pop()))
end

function macros.lte()
  return ast.push(ast.bin_op(">=", ast.pop(), ast.pop()))
end

function macros.gt()
  return ast.push(ast.bin_op("<", ast.pop(), ast.pop()))
end

function macros.gte()
  return ast.push(ast.bin_op("<=", ast.pop(), ast.pop()))
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
  return ast.table_at(ast.pop2nd(), ast.pop())
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

function macros.dot()
  return ast.code_seq(
    ast.func_call("io.write", ast.func_call("tostring", ast.pop())),
    ast.func_call("io.write", ast.literal("string", " ")))
end

function macros.cr()
  return ast.func_call("print")
end

function macros.def_lua_alias(compiler)
  local lua_name = compiler:word()
  forth_alias = compiler:word()
  compiler:alias(lua_name, forth_alias)
end

function macros.colon(compiler)
  local forth_name, arity, void = interop.parse_signature(compiler:word())
  local lua_name = sanitize(forth_name)
  compiler:def_word(forth_name, lua_name, false)
  return ast.func_header(lua_name, arity, void)
end

function macros.comment(compiler)
  repeat until ")" == compiler:next()
end

function macros.single_line_comment(compiler)
  repeat until "\n" == compiler:next()
end

function macros.var(compiler)
  local name = compiler:word()
  compiler:def_var(name, name)
  return ast.def_local(name)
end

function macros.assignment(compiler)
  local variable = compiler:word()
  return ast.assignment(variable, ast.pop())
end

function macros._if()
  return ast._if(ast.pop())
end

function macros._else()
  return ast.keyword("else")
end

function macros._begin()
  return ast._while(ast.literal("boolean", "true"))
end

function macros._until()
  return ast.code_seq(
    ast._if(ast.pop(), ast.keyword("break")),
    ast.keyword("end"))
end

function macros._while()
  return ast._if(ast.unary_op("not", ast.pop()), ast.keyword("break"))
end

function macros._case() -- simulate goto with break, in pre lua5.2 since GOTO was not yet supported
  return ast.keyword("repeat")
end

function macros._of()
  return ast.code_seq(
    ast.stack_op("over"),
    ast._if(ast.bin_op("==", ast.pop(), ast.pop())),
    ast.pop() -- drop selector
  )
end

function macros._endof() -- GOTO endcase
  return ast.code_seq(ast.keyword("break"), ast.keyword("end"))
end

function macros._endcase()
  return ast._until(ast.literal("boolean", "true"))
end

function macros._exit()
  return ast._return()
end

-- TODO this might overwrite user defined i/j ?
function macros._i()
  return ast.push(ast.aux_op("tos"))
end

-- TODO this might overwrite user defined i/j ?
function macros._j()
  return ast.push(ast.aux_op("tos2"))
end

function macros.unloop()
  return ast.aux_op("pop")
end

function macros._do(compiler)
  local var = gen_id("loop_var")
  return ast.code_seq(
    ast._for(
      var, ast.pop(),
      ast.bin_op("-", ast.pop(), ast.literal("number", 1)),
      nil),
    ast.aux_push(ast.identifier(var)))
end

function macros._loop()
  return ast.code_seq(
    ast.aux_op("pop"), -- unloop i/j
    ast.keyword("end"))
end

function macros.for_ipairs(compiler)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  -- TODO should be removed or we should maintain proper scope
  compiler:def_var(var_name1, var_name1)
  compiler:def_var(var_name2, var_name2)
  return ast._foreach(var_name1, var_name2, ast._ipairs(ast.pop()))
end

function macros.for_pairs(compiler)
  local var_name1 = compiler:word()
  local var_name2 = compiler:word()
  -- TODO should be removed or we should maintain proper scope
  compiler:def_var(var_name1, var_name1)
  compiler:def_var(var_name2, var_name2)
  return ast._foreach(var_name1, var_name2, ast._pairs(ast.pop()))
end

function macros._to(compiler)
  local loop_var = compiler:word()
  -- TODO should be removed or we should maintain proper scope
  compiler:def_var(loop_var, loop_var)
  return ast._for(loop_var, ast.pop2nd(), ast.pop(), nil)
end

function macros._step(compiler)
  local loop_var = compiler:word()
  -- TODO should be removed or we should maintain proper scope
  compiler:def_var(loop_var, loop_var)
  return ast._for(loop_var, ast.pop3rd(), ast.pop2nd(), ast.pop(), nil)
end

function macros._end()
  return ast.keyword("end")
end

function macros.words(compiler)
  for i, each in ipairs(compiler.word_list()) do
    io.write(each .. " ")
  end
  print()
end

return macros
