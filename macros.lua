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

function macros.def_lua_alias(compiler)
  -- local lua_name, _, _ = interop.parse_signature(compiler:word())
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
  local alias = compiler:word()
  local name = "v_" .. alias
  compiler:def_var(alias, name)
  compiler:emit_line("local " .. name)
end

function macros.assignment(compiler)
  local alias = compiler:word()
  local name = "v_" .. alias
  compiler:emit_line(name .. " = stack:pop()")
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
  compiler:emit_line("repeat")
end

function macros._until(compiler)
  compiler:emit_line("until(stack:pop())")
end

-- TODO this might overwrite user defined i/j ?
function macros._i(compiler)
  compiler:emit_line("stack:push(aux:tos())")
end

-- TODO this might overwrite user defined i/j ?
function macros._j(compiler)
  compiler:emit_line("stack:push(aux:tos2())")
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
