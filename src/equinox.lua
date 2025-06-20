__VERSION__=nil

local Compiler = require("compiler")
local Optimizer = require("ast_optimizer")
local CodeGen = require("codegen")
local Repl = require("repl")

local equinox = {}
local optimizer = Optimizer:new()
local compiler = Compiler:new(optimizer, CodeGen:new())
local repl = Repl:new(compiler, optimizer)

local lua_require = require

function require(module_name)
  if module_name:lower():match("%.eqx$") then
    return equinox.eval_file(module_name, false)
  else
    return lua_require(module_name)
  end
end

local lib = [[
alias: append #( table.insert 2 0 )
alias: insert #( table.insert 3 0 )
alias: remove #( table.remove 2 0 )
alias: >str #( tostring 1 1 )
alias: >num #( tonumber 1 1 )
alias: need #( require 1 1 )
alias: type #( type 1 1 )
alias: max  #( math.max 2 1 )
alias: min  #( math.min 2 1 )
alias: pow  #( math.pow 2 1 )
alias: # size
alias: emit #( string.char 1 1 ) #( io.write 1 0 )

: assert-true #( assert 1 0 ) ;
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
      "Table needs even number of items" #( error 1 )
    then
    2 / 0 do
      dup >a -rot ! a>
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

local function print_usage()
  print(string.format("Equinox %s Usage: equinox [FILE.EQX] [OPTIONS]", version()))
  print("Options:")
  print("\t-e\tEvaluate CLI parameter. E.g.: equinox -e '1 2 + .'")
  print("\t-d\tEnable debug mode.")
  print("\t-o0\tDisable optimizer.")
  print("\t-o1\tEnable optimizer (default).")
  print("\t-od\tDebug optimizer.")
  print("\t-repl\tStart REPL after evaluating a script.")
  print("To start the REPL run equinox with no parameters.")
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
  compiler:eval_text(lib)
end

function equinox.main(args)
  if #args < 1 then
    equinox.init()
    start_repl()
  else
    local log_result, repl = false, false
    local code, files = nil, {}
    local i = 1
    while i <= #args do
      param = args[i]
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
      elseif param == "-e" then
        code = args[i + 1]
        i = i + 1
      elseif param == "-h" or param == "--help" then
        print_usage()
        os.exit(0)
      else
        table.insert(files, param)
      end
      i = i + 1
    end
    equinox.init()
    if code then
      equinox.eval_text(code, log_result)
    else
      equinox.eval_files(files, log_result)
    end
    if repl then start_repl() end
  end
end

function equinox.eval_text(str, log_result)
  return compiler:eval_text(str, log_result)
end

function equinox.eval_file(str, log_result)
  return compiler:eval_file(str, log_result)
end

equinox.traceback = function(err)
  return compiler:traceback(err)
end

if arg and arg[0] and
  (arg[0]:match("equinox.lua$") or
   arg[0]:match("equinox_bundle.lua$")) then
  equinox.main(arg)
end

return equinox
