local stack = require("stack")
local aux = require("aux")
local interop = require("interop")
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
  compiler:emit_line("stack:push(stack:pop() + stack:pop())")
end

function macros.mul(compiler)
  compiler:emit_line("stack:push(stack:pop() * stack:pop())")
end

function macros.sub(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_b - _a)]])
end

function macros.div(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_b / _a)]])
end

function macros.mod(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_b % _a)]])
end

function macros.eq(compiler)
  compiler:emit_line("stack:push(stack:pop() == stack:pop())")
end

function macros.neq(compiler)
  compiler:emit_line("stack:push(stack:pop() ~= stack:pop())")
end

function macros.lt(compiler)
  compiler:emit_line("stack:push(stack:pop() > stack:pop())")
end

function macros.lte(compiler)
  compiler:emit_line("stack:push(stack:pop() >= stack:pop())")
end

function macros.gt(compiler)
  compiler:emit_line("stack:push(stack:pop() < stack:pop())")
end

function macros.gte(compiler)
  compiler:emit_line("stack:push(stack:pop() <= stack:pop())")
end

function macros._not(compiler)
  compiler:emit_line("stack:push(not stack:pop())")
end

function macros._and(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_a and _b)]])
end

function macros._or(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_a or _b)]])
end

function macros.concat(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_b .. _a)]])
end

function macros.new_table(compiler)
  compiler:emit_line("stack:push({})")
end

function macros.table_size(compiler)
  compiler:emit_line("stack:push(#stack:pop())")
end

function macros.table_at(compiler)
  compiler:emit_line([[
local _n = stack:pop()
local _t = stack:pop()
stack:push(_t[_n])]])
end

function macros.table_put(compiler)
  compiler:emit_line([[
local _val = stack:pop()
local _key = stack:pop()
local _tbl = stack:pop()
_tbl[_key] = _val]])
end

function macros.depth(compiler)
  compiler:emit_line("stack:push(stack:depth())")
end

function macros.adepth(compiler)
  compiler:emit_line("stack:push(aux:depth())")
end

function macros.dup(compiler)
  compiler:emit_line("stack:push(stack:tos())")
end

function macros.drop(compiler)
  compiler:emit_line("stack:pop()")
end

function macros.over(compiler)
  compiler:emit_line("stack:push(stack:tos2())")
end

function macros.rot(compiler)
  compiler:emit_line([[
local _c = stack:pop()
local _b = stack:pop()
local _a = stack:pop()
stack:push(_b)
stack:push(_c)
stack:push(_a)]])
end

function macros.swap(compiler)
  compiler:emit_line([[
local _a = stack:pop()
local _b = stack:pop()
stack:push(_a)
stack:push(_b)]])
end

function macros.to_aux(compiler)
  compiler:emit_line("aux:push(stack:pop())")
end

function macros.from_aux(compiler)
  compiler:emit_line("stack:push(aux:pop())")
end

function macros.dot(compiler)
  compiler:emit_line([[
io.write(tostring(stack:pop()))
io.write(" ")]])
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
  if not arity or arity == 0 then
    compiler:emit_line("function " .. lua_name .. "()")
  else
    compiler:emit("function " .. lua_name .. "(")
    for i = 1, arity do
      compiler:emit("__a" .. i)
      if i < arity then
        compiler:emit(",")
      else
        compiler:emit_line(")")
      end
    end
    for i = 1, arity do
      compiler:emit_line("stack:push(__a" .. i ..")")
    end
  end
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
  compiler:emit_line("local " .. name)
end

function macros.assignment(compiler)
  compiler:emit_line(compiler:word() .. " = stack:pop()")
end

function macros._if(compiler)
  compiler:emit_line("if stack:pop() then")
end

function macros._else(compiler)
  compiler:emit_line("else")
end

function macros._then(compiler)
  compiler:emit_line("end")
end

function macros._begin(compiler)
  local line_number = compiler:line_number()
  compiler:emit_line("-- placeholder begin")
  stack:push(line_number)
end

function macros._until(compiler)
  local line_number = stack:pop()
  compiler:update_line("repeat", line_number)
  compiler:emit_line("until(stack:pop())", line_number)
end

function macros._while(compiler)
  compiler:emit_line("if not stack:pop() then break end")
end

function macros._repeat(compiler)
  local line_number = stack:pop()
  compiler:update_line("while(true) do", line_number)
  compiler:emit_line("end")
end

function macros._case(compiler)
  -- simulate goto with break, in pre lua5.2 since GOTO was not yet supported
  compiler:emit_line("repeat")
end

function macros._of(compiler)
  compiler:emit_line("stack:push(stack:tos2())") -- OVER
  compiler:emit_line("if stack:pop() == stack:pop() then")
  compiler:emit_line("stack:pop()") -- DROP selector value
end

function macros._endof(compiler)
  compiler:emit_line("break end") -- GOTO endcase
end

function macros._endcase(compiler)
  compiler:emit_line("until true")
end

function macros._exit(compiler)
  compiler:emit_line("do return end")
end

-- TODO this might overwrite user defined i/j ?
function macros._i(compiler)
  compiler:emit_line("stack:push(aux:tos())")
end

-- TODO this might overwrite user defined i/j ?
function macros._j(compiler)
  compiler:emit_line("stack:push(aux:tos2())")
end

function macros.unloop(compiler)
  compiler:emit_line("aux:pop()")
end

function macros._do(compiler)
  local var = gen_id("loop_var")
  compiler:emit_line("for ".. var .."=stack:pop(), stack:pop() -1 do")
  compiler:emit_line("aux:push(".. var ..")")
end

function macros._loop(compiler)
  compiler:emit_line("aux:pop()") -- unloop i/j
  compiler:emit_line("end")
end

function macros._end(compiler)
  compiler:emit_line("end")
end

function macros.words(compiler)
  for i, each in ipairs(compiler.word_list()) do
    io.write(each .. " ")
  end
  print()
end

return macros
