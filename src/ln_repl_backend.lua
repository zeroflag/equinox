local console = require("console")
local utils = require("utils")
local ln = require("linenoise")

ln.enableutf8()

local Backend = {}

function Backend:new(compiler, history_file, commands)
  local obj = {compiler = compiler,
               input = "",
               commands = commands,
               history_file = history_file}
  setmetatable(obj, {__index = self})
  if history_file then
    ln.historyload(history_file)
  end
  obj:setup()
  return obj
end

function Backend:setup()
  ln.setcompletion(function(completion, str)
    for _, match in ipairs(self:completer(str)) do
      completion:add(match)
    end
  end)
end

local function add_completions(input, words, result)
  for _, word in ipairs(words) do
    local before, after = input:match("^(.*)%s(.*)$")
    if not after then
      after = input
      before = ""
    else
      before = before .. " "
    end
    if utils.startswith(word, after) then
      table.insert(result, before .. word)
    end
  end
end

local function resolve(input)
  local obj = _G
  for part in input:gmatch("[^%.]+") do
    if obj[part] then
      obj = obj[part]
    else
      return obj
    end
  end
  return obj
end

local function add_props(input, result)
  local obj = resolve(input)
  if type(obj) ~= "table" or obj == _G then
    return
  end
  local prefix = input:match("(.+%.)")
  if not prefix then prefix = "" end
  local last = input:match("[^%.]+$")
  for key, val in pairs(obj) do
    if not last or utils.startswith(key, last) then
      table.insert(result, prefix .. key)
    end
  end
end

local function add_commands(input, result, commands)
  for _, cmd in ipairs(commands) do
    if utils.startswith(cmd, input) then
      table.insert(result, cmd)
    end
  end
end

local function modules()
  local result = {}
  for key, val in pairs(_G) do
    if type(val) == "table" then
      table.insert(result, key)
    end
  end
  return result
end

function Backend:completer(input)
  local matches = {}
  add_completions(input, self.compiler:word_list(), matches)
  add_completions(input, self.compiler:var_names(), matches)
  add_commands(input, matches, self.commands)
  if input:find("%.") then
    add_props(input, matches)
  else
    add_completions(input, modules(), matches)
  end
  return utils.unique(matches)
end

function Backend:prompt()
  if self.multi_line then
    return "..."
  else
    return "#"
  end
end

function Backend:save_history(input)
  if self.history_file then
    ln.historyadd(input)
    ln.historysave(self.history_file)
  end
end

function Backend:read_line(prompt)
  return utils.trim(ln.linenoise(prompt .. " "))
end

function Backend:read()
  local prompt = console.colorize(self:prompt(), console.PURPLE)
  if self.multi_line then
    self.input = self.input .. "\n" .. self:read_line(prompt)
  else
    self.input = self:read_line(prompt)
  end
  return self.input
end

function Backend:set_multiline(bool)
  self.multi_line = bool
  ln.setmultiline(bool)
end

return Backend
