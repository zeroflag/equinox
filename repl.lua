local compiler = require("compiler")

compiler:eval_file("lib.eqx")

while true do
  io.write("$ ")
  local input = io.read()
  if input == "exit" then
    break
  end
  compiler:eval(input)
end
