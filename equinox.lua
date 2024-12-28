compiler = require("compiler")
repl = require("repl")

local equinox = {}

function equinox.main()
  compiler:eval_file("lib.eqx")
  if #arg < 1 then
    repl.welcome()
    repl.start()
  else
    local filename = arg[1]
    print("Loading " .. filename)
    compiler:eval_file(filename)
  end
end

function equinox.eval(str)
  return compiler:eval(str)
end

function equinox.eval_file(str)
  return compiler:eval_file(str)
end

if arg and arg[0] == "equinox.lua" then
  equinox.main(arg)
end

return equinox
