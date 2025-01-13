__VERSION__=nil

local Compiler = require("compiler")
local Optimizer = require("ast_optimizer")
local CodeGen = require("codegen")
local Repl = require("repl")

local equinox = {}
local optimizer = Optimizer.new()
local compiler = Compiler.new(optimizer, CodeGen.new())
local repl = Repl.new(compiler, optimizer)

local lua_require = require

function require(module_name)
  if module_name:lower():match("%.eqx$") then
    return equinox.eval_file(module_name, false)
  else
    return lua_require(module_name)
  end
end

local lib = [[
lua-alias: table.insert~2 append
lua-alias: table.insert~3 insert
lua-alias: table.remove~2 remove
lua-alias: tostring/1 >str

: assert-true assert~1 ;
: assert-false not assert-true ;
: =assert = assert-true ;

: [ depth >a ;
: ]
  []
  depth a> - 1 - 0
  do
    dup >a
    1 rot insert ( tbl idx value )
    a>
  loop ;

: { depth >a ;
: }
    {}
    depth a> - 1 -
    dup 2 % 0 != if
      "Table needs even number of items" error/1
    then
    2 / 0 do
      dup >a -rot put a>
    loop ;
]]

local function version()
  if __VERSION__ then
    return __VERSION__
  else
    version = require("version/version")
    version.load()
    return version.current
  end
end

local function start_repl()
  repl:welcome(version())
  repl:start()
end

function equinox.eval_files(files, log_result)
  local result = nil
  for i, filename in ipairs(files) do
    if log_result then
      print("Loading " .. filename)
    end
    result = equinox.eval_file(filename, log_result)
  end
  return result
end

function equinox.init()
  compiler:eval(lib)
end

function equinox.main()
  if #arg < 1 then
    equinox.init()
    start_repl()
  else
    local log_result, repl = false, false
    local files = {}
    for i, param in ipairs(arg) do
      if param == "-d" then
        log_result = true
      elseif param == "-o0" then
        optimizer:enable(false)
      elseif param == "-o1" then
        optimizer:enable(true)
      elseif param == "-od" then
        optimizer:enable_logging(true)
      elseif param == "-repl" then
        repl = true
      else
        table.insert(files, param)
      end
    end
    equinox.init()
    equinox.eval_files(files, log_result)
    if repl then start_repl() end
  end
end

function equinox.eval(str, log_result)
  return compiler:eval(str, log_result)
end

function equinox.eval_file(str, log_result)
  return compiler:eval_file(str, log_result)
end

if arg and arg[0] and
  (arg[0]:match("equinox.lua$") or
   arg[0]:match("equinox_bundle.lua$")) then
  equinox.main(arg)
end

return equinox
