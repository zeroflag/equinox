local stack = require("stack")
local utils = require("utils")
local console = require("console")
local Source = require("source")

local function load_backend(preferred, fallback)
  local success, mod = pcall(require, preferred)
  if success then
    return mod
  else
    return require(fallback)
  end
end

local Repl = {}

local repl_ext = "repl_ext.eqx"

local commands = {
  bye = "bye",
  help = "help",
  log_on = "log-on",
  log_off = "log-off",
  stack_on = "stack-on",
  stack_off = "stack-off",
  opt_on = "opt-on",
  opt_off = "opt-off",
  load_file = "load-file"
}

function Repl:new(compiler, optimizer)
  local ReplBackend = load_backend("ln_repl_backend", "simple_repl_backend")
  local obj = {backend = ReplBackend:new(
                 compiler,
                 utils.in_home(".equinox_repl_history"),
                 utils.values(commands)),
               compiler = compiler,
               optimizer = optimizer,
               ext_dir = os.getenv("EQUINOX_EXT_DIR") or "./ext",
               always_show_stack = false,
               repl_ext_loaded = false,
               log_result = false }
  setmetatable(obj, {__index = self})
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
  console.message(string.format([[
 __________________          _-_
 \__(=========/_=_/ ____.---'---`---.___
            \_ \    \----._________.---/
              \ \   /  /    `-_-'
         ___,--`.`-'..'-_
        /____          (|
              `--.____,-'   v%s
]], version), console.CYAN)
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
- help "show this help"]])
end

function Repl:read()
  return self.backend:read()
end

function Repl:process_commands(input)
  local command = utils.trim(input)
  if command == commands.bye then
    os.exit(0)
  end
  if command == commands.help then
    show_help()
    return true
  end
  if command == commands.log_on then
    self.log_result = true
    print("Log turned on")
    return true
  end
  if command == commands.log_off then
    self.log_result = false
    print("Log turned off")
    return true
  end
  if command == commands.stack_on then
    if self.repl_ext_loaded then
      self.always_show_stack = true
      print("Show stack after input is on")
    else
      print("Requires " .. repl_ext)
    end
    return true
  end
  if command == commands.stack_off then
    self.always_show_stack = off
    print("Show stack after input is off")
    return true
  end
  if command == commands.opt_on then
    self.optimizer:enable(true)
    print("Optimization turned on")
    return true
  end
  if command == commands.opt_off then
    self.optimizer:enable(false)
    print("Optimization turned off")
    return true
  end
  if command:sub(1, #commands.load_file) == commands.load_file
  then
    local path = utils.trim(command:sub(#commands.load_file + 1))
    if path and path ~= "" then
      if not utils.exists(path) and not utils.extension(path) then
        path = path .. ".eqx"
      end
      if not utils.exists(path) and
        not (string.find(path, "/") or
              string.find(path, "\\"))
      then
        path = utils.join(self.ext_dir, path)
      end
      if utils.exists(path) then
        self:safe_call(function() self.compiler:eval_file(path) end)
      else
        print("File does not exist: " .. path)
      end
    else
      print("Missing file path.")
    end
    return true
  end
  return false
end

function Repl:print_err(result)
  console.message("Red Alert: ", console.RED, true)
  print(tostring(result))
end

function Repl:print_ok()
  if stack:depth() > 0 then
    console.message("OK(".. stack:depth()  .. ")", console.GREEN)
    if self.always_show_stack and self.repl_ext_loaded then
      self.compiler:eval_text(".s")
    end
  else
    console.message("OK", console.GREEN)
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
  local ext = utils.file_exists_in_any_of(repl_ext, {self.ext_dir})
  if ext then
    self.compiler:eval_file(ext)
    self.repl_ext_loaded = true
  end
  while true do
    local input = self:read()
    if self:process_commands(input) then
      self.backend:save_history(input)
    else
      local success, result = pcall(function ()
          return self.compiler:compile_and_load(
            Source:from_text(input), self.log_result)
      end)
      if not success then
        self:print_err(result)
      elseif not result then
        self.backend:set_multiline(true)
        self.compiler:reset_state()
      else
        self.backend:set_multiline(false)
        self:safe_call(function() result() end)
        self.backend:save_history(input:gsub("[\r\n]", " "))
      end
    end
  end
end

return Repl
