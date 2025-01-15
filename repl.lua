local stack = require("stack")

local SINGLE_LINE = 1
local MULTI_LINE = 2

local Repl = {}

local function join(dir, child)
  if not dir or "" == dir then return child end
  local sep = ""
  if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then
    sep = package.config:sub(1, 1)
  end
  return dir .. sep .. child
end

local repl_ext = "repl_ext.eqx"
local home = os.getenv("HOME") or os.getenv("USERPROFILE")
local search_paths = { join(home, ".equinox"), "" }

local function file_exists(filename)
  local file = io.open(filename, "r")
  if file then file:close() return true
  else return false end
end

local function file_exists_in_any_of(filename, dirs)
  for i, dir in ipairs(dirs) do
    local path = join(dir, filename)
    if file_exists(path) then
      return path
    end
  end
  return nil
end

local function extension(filename)
  return filename:match("^.+(%.[^%.]+)$")
end

function Repl.new(compiler, optimizer)
  local obj = {compiler = compiler,
               optimizer = optimizer,
               mode = SINGLE_LINE,
               always_show_stack = false,
               repl_ext_loaded = false,
               input = "",
               log_result = false }
  setmetatable(obj, {__index = Repl})
  return obj
end

local messages = {
  "The Prime Directive: Preserve Stack Integrity at All Costs.",
  "Engage warp speed and may your stack never overflow.",
  "Welcome Commander. The stack is ready for your orders.",
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

function Repl:welcome(version)
  print("Equinox Forth Console (" .. _VERSION .. ") @ Delta Quadrant.")
  print(messages[math.random(1, #messages)])
  print("\27[1;96m")
  print(string.format([[
 ___________________          _-_
 \__(==========/_=_/ ____.---'---`---.____
             \_ \    \----._________.----/
               \ \   /  /    `-_-'
          ___,--`.`-'..'-_
         /____          (|
               `--.____,-'   v%s
]], version))
  print("\27[0m")
  print("Type 'words' for wordlist, 'bye' to exit or 'help'.")
  print("First time Forth user? Type: load-file tutorial")
end

local function show_help()
  print([[
- log-on "turn on logging"
- log-off "turn off logging"
- opt-on "turn on optimization"
- opt-off "turn off optimization"
- load-file <path> "load an eqx file"
- stack-on "always show stack after each input"
- stack-off "don't show stack after each input"
- bye "exit repl"
- help "show this help"
  ]])
end

function Repl:prompt()
  if self.mode == SINGLE_LINE then
    return "#"
  else
    return "..."
  end
end

function Repl:show_prompt()
  io.write(string.format("\27[1;95m%s \27[0m", self:prompt()))
end

function Repl:read()
  if self.mode == SINGLE_LINE then
    self.input = io.read()
  else
    self.input = self.input .. "\n" .. io.read()
  end
end

local function trim(str)
  return str:match("^%s*(.-)%s*$")
end

function Repl:process_commands()
  local command = trim(self.input)
  if command == "bye" then
    os.exit(0)
  end
  if command == "help" then
    show_help()
    return true
  end
  if command == "log-on" then
    self.log_result = true
    print("Log turned on")
    return true
  end
  if command == "log-off" then
    self.log_result = false
    print("Log turned off")
    return true
  end
  if command == "stack-on" then
    if self.repl_ext_loaded then
      self.always_show_stack = true
      print("Show stack after input is on")
    else
      print("Requires " .. repl_ext)
    end
    return true
  end
  if command == "stack-off" then
    self.always_show_stack = off
    print("Show stack after input is off")
    return true
  end
  if command == "opt-on" then
    self.optimizer:enable(true)
    print("Optimization turned on")
    return true
  end
  if command == "opt-off" then
    self.optimizer:enable(false)
    print("Optimization turned off")
    return true
  end
  local path = command:match("load%-file%s+(.+)")
  if path then
    if not file_exists(path) and not extension(path) then
      path = path .. ".eqx"
    end
    if file_exists(path) then
      self:safe_call(function() self.compiler:eval_file(path) end)
    else
      print("File does not exist: " .. path)
    end
    return true
  end
  return false
end

function Repl:print_err(result)
  print("\27[91m" .. "Red Alert: " .. "\27[0m" .. tostring(result))
end

function Repl:print_ok()
  if stack:depth() > 0 then
    print("\27[92m" .. "OK(".. stack:depth()  .. ")" .. "\27[0m")
    if self.always_show_stack and self.repl_ext_loaded then
      self.compiler:eval(".s")
    end
  else
    print("\27[92mOK\27[0m")
  end
end

function Repl:safe_call(func)
  local success, result = pcall(func)
  if success then
    self:print_ok()
  else
    self:print_err(result)
  end
end

function Repl:start()
  local ext = file_exists_in_any_of(repl_ext, search_paths)
  if ext then
    self.compiler:eval_file(ext)
    self.repl_ext_loaded = true
  end
  local prompt = "#"
  while true do
    self:show_prompt()
    self:read()
    if not self:process_commands() then
      local success, result = pcall(function ()
          return self.compiler:compile_and_load(self.input, self.log_result)
      end)
      if not success then
        self:print_err(result)
      elseif not result then
        self.mode = MULTI_LINE
        self.compiler:reset_state()
      else
        self.mode = SINGLE_LINE
        self:safe_call(function() result() end)
      end
    end
  end
end

return Repl
