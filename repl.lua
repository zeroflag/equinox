local compiler = require("compiler")
local stack = require("stack")

local repl = {}

function repl.welcome(version)
  print("Welcome to the Delta Quadrant on Equinox (" .. _VERSION .. ")")
  print("Engage warp speed and may your stack never overflow.")

  print("\27[1;96m")
  print(string.format([[
 ___________________          _-_
 \__(==========/_=_/ ____.---'---`---.____
             \_ \    \----._________.----/
               \ \   /  /    `-_-'
          ___,--`.`-'..'-_
         /____          ||
               `--.____,-'   v%s
]], version))
  print("\27[0m")
  print("Type 'words' for wordlist, 'bye' to exit or 'help'.")
end

function show_help()
  print([[
- log-on: turn on logging
- log-off: turn off logging
- bye: exit repl
- help: show this help
  ]])
end

function repl.start()
  local log_result = false
  local prompt = "#"
  while true do
    io.write(string.format("\27[1;95m%s \27[0m", prompt))
    local input = io.read()
    if input == "bye" then
      break
    elseif input == "help" then
      show_help()
    elseif input == "log-on" then
      log_result = true
      print("Log turned on")
    elseif input == "log-off" then
      log_result = false
      print("Log turned off")
    else
      local status, result = pcall(
        function()
          return compiler:eval(input, log_result)
        end)
      if status then
        if stack:depth() > 0 then
          print("\27[92m" .. "OK(".. stack:depth()  .. ")" .. "\27[0m")
        else
          print("\27[92mOK\27[0m")
        end
      else
        print("\27[91m" ..result .. "\27[0m")
      end
    end
  end
end

return repl
