local compiler = require("compiler")

while true do
  io.write("$ ")
  local input = io.read()
  if input == "exit" then
    break
  end
  compiler:eval_file("lib.eqx")
  compiler:eval(input)
end
