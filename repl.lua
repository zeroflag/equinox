local compiler = require("compiler")
local stack = require("stack")

local SINGLE_LINE = 1
local MULTI_LINE = 2

local repl = { mode = SINGLE_LINE, input = "", log_result = false }

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

function repl.prompt()
  if repl.mode == SINGLE_LINE then
    return "#"
  else
    return "..."
  end
end

function repl.show_prompt()
  io.write(string.format("\27[1;95m%s \27[0m", repl.prompt()))
end

function repl.read()
  if repl.mode == SINGLE_LINE then
    repl.input = io.read()
  else
    repl.input = repl.input .. "\n" .. io.read()
  end
end

function repl.process_commands()
  if repl.input == "bye" then
    os.exit(0)
  end
  if repl.input == "help" then
    show_help()
    return true
  end
  if repl.input == "log-on" then
    repl.log_result = true
    print("Log turned on")
    return true
  end
  if repl.input == "log-off" then
    repl.log_result = false
    print("Log turned off")
    return true
  end
  return false
end

function repl.start()
  local prompt = "#"
  while true do
    repl.show_prompt()
    repl.read()
    if not repl.process_commands() then
      local result = compiler:compile_and_load(repl.input, repl.log_result)
      if not result then
        repl.mode = MULTI_LINE
      else
        repl.mode = SINGLE_LINE
        local status, result = pcall(function() result() end)
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
end

return repl
