local stack = require("stack")
local aux = require("aux")
local interop = require("interop")
local ast = require("ast")

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

function macros.add(compiler)
  return ast.bin_op("+", ast.pop(), ast.pop())
end

function macros.mul(compiler)
  return ast.bin_op("*", ast.pop(), ast.pop())
end

function macros.sub(compiler)
  return ast.bin_op("-", ast.pop2nd(), ast.pop())
end

function macros.div(compiler)
  return ast.bin_op("/", ast.pop2nd(), ast.pop())
end

function macros.mod(compiler)
  return ast.bin_op("%", ast.pop2nd(), ast.pop())
end

function macros.eq(compiler)
  return ast.bin_op("==", ast.pop(), ast.pop())
end

function macros.neq(compiler)
  return ast.bin_op("~=", ast.pop(), ast.pop())
end

function macros.lt(compiler)
  return ast.bin_op(">", ast.pop(), ast.pop())
end

function macros.lte(compiler)
  return ast.bin_op(">=", ast.pop(), ast.pop())
end

function macros.gt(compiler)
  return ast.bin_op("<", ast.pop(), ast.pop())
end

function macros.gte(compiler)
  return ast.bin_op("<=", ast.pop(), ast.pop())
end

function macros._not(compiler)
  return ast.unary_op("not", ast.pop())
end

function macros._and(compiler)
  return ast.bin_op("and", ast.pop(), ast.pop(), true)
end

function macros._or(compiler)
  return ast.bin_op("or", ast.pop(), ast.pop(), true)
end

function macros.concat(compiler)
  return ast.bin_op("..", ast.pop2nd(), ast.pop())
end

function macros.new_table(compiler)
  return ast.new_table()
end

function macros.table_size(compiler)
  return ast.unary_op("#", ast.pop())
end

function macros.table_at(compiler)
  return ast.table_at(ast.pop2nd(), ast.pop())
end

function macros.table_put(compiler)
  return ast.table_put(ast.pop3rd(), ast.pop2nd(), ast.pop())
end

function macros.depth(compiler)
  compiler:emit_push("stack:depth()")
  --return ast.stack_op("depth")
end

function macros.adepth(compiler)
  compiler:emit_push("aux:depth()")
  --return ast.aux_op("depth")
end

function macros.dup(compiler)
  return ast.stack_op("dup")
end

function macros.drop(compiler)
  return ast.pop()
end

function macros.over(compiler)
  return ast.stack_op("over")
end

function macros.nip(compiler)
  return ast.stack_op("nip")
end

function macros.dup2(compiler)
  return ast.stack_op("dup2")
end

function macros.mrot(compiler)
  return ast.stack_op("mrot")
end

function macros.tuck(compiler)
  return ast.stack_op("tuck")
end

function macros.rot(compiler)
  return ast.stack_op("rot")
end

function macros.swap(compiler)
  return ast.stack_op("swap")
end

function macros.to_aux(compiler)
  compiler:emit_line("aux:push(stack:pop())")
  --return ast.to_aux(ast.pop())
end

function macros.from_aux(compiler)
  compiler:emit_push("aux:pop()")
  --return ast.from_aux()
end

function macros.dot(compiler)
  compiler:emit_line([[
io.write(tostring(stack:pop()))
io.write(" ")]])
  --return ast.unary_op(".", ast.pop()))
end

function macros.cr(compiler)
  compiler:emit_line("print()")
  --return ast.nullary_operator("cr")
  -- fcall
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

function macros._if(compiler)
  return ast._if(ast.pop())
end

function macros._else(compiler)
  return ast._else()
end

function macros._begin(compiler)
  compiler:emit_line("while(true) do")
  --return ast._while(ast.literal("boolean", "true"))
end

function macros._until(compiler)
  compiler:emit_line("if stack:pop() then break end")
  compiler:emit_line("end")
end

function macros._while(compiler)
  compiler:emit_line("if not stack:pop() then break end")
  --return ast._if(ast.unary_op("not", ast.pop())))
  --return ast._break())
  --return ast._end())
end

function macros._case(compiler)
  -- simulate goto with break, in pre lua5.2 since GOTO was not yet supported
  return ast._repeat()
end

function macros._of(compiler)
  compiler:emit_push("stack:tos2()") -- OVER
  compiler:emit_line("if stack:pop() == stack:pop() then")
  compiler:emit_line("stack:pop()") -- DROP selector value
--[[
  return ast.stack_op("over"))
  return ast._if(ast.bin_op("==", ast.pop(), ast.pop())))
  return ast.pop())
--]]
end

function macros._endof(compiler)
  compiler:emit_line("break end") -- GOTO endcase
  --ast._break()
  --return ast._end()
end

function macros._endcase(compiler)
  compiler:emit_line("until true")
  --return ast._until(ast.literal("boolean", "true"))
end

function macros._exit(compiler)
  return ast._return()
end

-- TODO this might overwrite user defined i/j ?
function macros._i(compiler)
  compiler:emit_push("aux:tos()")
  --return ast.aux_op("tos")
end

-- TODO this might overwrite user defined i/j ?
function macros._j(compiler)
  compiler:emit_push("aux:tos2()")
  --return ast.aux_op("tos2")
end

function macros.unloop(compiler)
  compiler:emit_line("aux:pop()")
  --return ast.aux_op("drop")
end

function macros._do(compiler)
  local var = gen_id("loop_var")
  compiler:emit_line("for ".. var .."=stack:pop(), stack:pop() -1 do")
  compiler:emit_line("aux:push(".. var ..")")
--[[
  return ast._for(
                      var,
                      ast.pop(),
                      ast.bin_op("-", ast.literal("number", 1), ast.pop()),
                      nil))
  return ast.aux_push(ast.var_ref(var)))
--]]
end

function macros._loop(compiler)
  compiler:emit_line("aux:pop()") -- unloop i/j
  compiler:emit_line("end")
  --return ast.aux_op("pop")
  --return ast._end()
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

function macros._end(compiler)
  return ast._end()
end

function macros.words(compiler)
  for i, each in ipairs(compiler.word_list()) do
    io.write(each .. " ")
  end
  print()
end

return macros
