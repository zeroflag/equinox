local Compiler = require("compiler")
local Optimizer = require("ast_optimizer")
local CodeGen = require("codegen")
local stack = require("stack")

local SINGLE_LINE = 1
local MULTI_LINE = 2

local optimizer = Optimizer.new()
local compiler = Compiler.new(optimizer, CodeGen.new())

local repl = { mode = SINGLE_LINE, input = "", log_result = false }

local messages = {
  "The Prime Directive: Preserve Stack Integrity at All Costs.",
  "Engage warp speed and may your stack never overflow.",
  "Welcome aboard Commander. The stack is ready for your orders.",
  "Our mission is to explore new words and seek out new stack operations.",
  "Welcome, Officer. May your debugging skills be as sharp as a phaser.",
  "Your mission is to PUSH the boundaries of programming.",
  "In the Delta Quadrant every stack operation is a new discovery.",
  "One wrong stack move and your program could warp into an infinite loop.",
  "Take responsibility for your code as errors will affect the entire fleet.",
  "Picard's programming tip: Complexity can be a form of the enemy.",
  "Spock's programming tip: Logic is the foundation of all good code.",
  "Spock's programming tip: Do not let emotion cloud your debugging.",
  "Worf's programming tip: A true programmer fights for correctness.",
  "Worf's programming tip: When facing a bug, fire your phasers at full power.",
  "One misplaced DROP can send your code into warp core breach.",
  "To reach warp speed, the code must be optimized for maximum efficiency.",
  "Working in Forth sometimes feels like working in a Jeffries tube.",
  "A balanced stack is a stable warp core. Keep it well protected.",
  "All systems are stable, commander. Stack integrity is 100%.",
  "Captain, the stack is clear and ready for warp.",
  "Deflector shields holding steady captain, the stack is well protected."
}

math.randomseed(os.time())

function repl.welcome(version)
  print("Equinox Forth Console (" .. _VERSION .. ") @ Delta Quadrant.")
  print(messages[math.random(1, #messages)])
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
- log-on "turn on logging"
- log-off "turn off logging"
- opt-on "turn on optimization"
- opt-off "turn off optimization"
- load-file <path> "load an eqx file"
- bye "exit repl"
- help "show this help"
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

function trim(str)
  return str:match("^%s*(.-)%s*$")
end

function repl.process_commands()
  local command = trim(repl.input)
  if command == "bye" then
    os.exit(0)
  end
  if command == "help" then
    show_help()
    return true
  end
  if command == "log-on" then
    repl.log_result = true
    print("Log turned on")
    return true
  end
  if command == "log-off" then
    repl.log_result = false
    print("Log turned off")
    return true
  end
  if command == "opt-on" then
    optimizer:enable(true)
    print("Optimization turned on")
    return true
  end
  if command == "opt-off" then
    optimizer:enable(false)
    print("Optimization turned off")
    return true
  end
  local path = command:match("load%-file%s+(.+)")
  if path then
    safe_call(function() compiler:eval_file(path) end)
    return true
  end
  return false
end

function repl.print_err(result)
  print("\27[91m" .. "Red Alert: " .. "\27[0m" .. result)
end

function repl.print_ok()
  if stack:depth() > 0 then
    print("\27[92m" .. "OK(".. stack:depth()  .. ")" .. "\27[0m")
  else
    print("\27[92mOK\27[0m")
  end
end

function safe_call(func)
  local success, result = pcall(func)
  if success then
    repl.print_ok()
  else
    repl.print_err(result)
  end
end

function repl.start()
  local prompt = "#"
  while true do
    repl.show_prompt()
    repl.read()
    if not repl.process_commands() then
      local success, result = pcall(function ()
          return compiler:compile_and_load(repl.input, repl.log_result)
      end)
      if not success then
        repl.print_err(result)
      elseif not result then
        repl.mode = MULTI_LINE
      else
        repl.mode = SINGLE_LINE
        safe_call(function() result() end)
      end
    end
  end
end

return repl
