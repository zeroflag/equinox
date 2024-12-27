compiler = require("compiler")

if #arg < 1 then
  print("Usage: lua equinox.lua <script.eqx>")
  os.exit(1)
end

local filename = arg[1]

compiler:eval_file("lib.eqx")
compiler:eval_file(filename)
