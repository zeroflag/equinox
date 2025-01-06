compiler = require("compiler")
repl = require("repl")

local equinox = {}

function start_repl()
  compiler:eval_file("lib.eqx")
  repl.welcome(version.current)
  repl.start()
end

function eval_files(files, log_result)
  compiler:eval_file("lib.eqx")
  for i, filename in ipairs(files) do
    if log_result then
      print("Loading " .. filename)
    end
    equinox.eval_file(filename, log_result)
  end
end

function equinox.main()
  version = require("version/version")
  version.load()
  if #arg < 1 then
    start_repl()
  else
    local log_result = false
    local files = {}
    for i, param in ipairs(arg) do
      if param == "-d" then
        log_result = true
      elseif param == "-o0" then
        compiler.optimization = false
      elseif param == "-o1" then
        compiler.optimization = true
      elseif param == "-od" then
        compiler.log_opt = true
      else
        table.insert(files, param)
      end
    end
    eval_files(files, log_result)
  end
end

function equinox.eval(str, log_result)
  return compiler:eval(str, log_result)
end

function equinox.eval_file(str, log_result)
  return compiler:eval_file(str, log_result)
end

if arg and (arg[0]:match("equinox.lua$")
            or arg[0]:match("equinox_bundle.lua$")) then
  equinox.main(arg)
end

return equinox
