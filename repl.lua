local compiler = require("compiler")
local stack = require("stack")

local repl = {}

function repl.welcome()
  print("Welcome to the Delta Quadrant on Equinox (" .. _VERSION .. ")")
  print("Engage warp speed and may your stack never overflow.")

  print([[
 ___________________          _-_
 \__(==========/_=_/ ____.---'---`---.____
             \_ \    \----._________.----/
               \ \   /  /    `-_-'
           __,--`.`-'..'-_
         /____          ||
               `--.____,-'
  ]])
  print("Type words to see wordlist or bye to exit.")
end

function repl.start()
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
      if stack:depth() > 0 then
        print("ok (" .. stack:depth() .. ")")
      else
        print("ok")
      end
    else
      print(result)
    end
  end
end

return repl
