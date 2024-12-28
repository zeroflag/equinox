local compiler = require("compiler")
compiler:eval_file("lib.eqx")

print("Welcome to the Delta Quadrant on Equinox (" .. _VERSION .. ")")
print("Engage warp speed and may your stack never overflow.")
print("Type words to see wordlist and bye to exit.\n")

while true do
  io.write("# ")
  local input = io.read()
  if input == "bye" then
    break
  end
  local status, result = pcall(
    function()
      return compiler:eval(input)
    end)
  if status then
    print("ok")
  else
    print(result)
  end
end
