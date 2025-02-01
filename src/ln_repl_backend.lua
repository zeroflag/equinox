local console = require("console")
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

function Backend:completer(input)
  local matches = {}
  for _, word in ipairs(self.compiler:word_list()) do
    local before, after = input:match("^(.*)%s(.*)$")
    if not after then
      after = input
      before = ""
    else
      before = before .. " "
    end
    if word:find("^" .. after) then
      table.insert(matches, before .. word)
    end
  end
  for _, cmd in ipairs(self.commands) do
    if cmd:find("^" .. input) then
      table.insert(matches, cmd)
    end
  end
  return matches
end

function Backend:prompt()
  if self.multi_line then
    return "..."
  else
    return "#"
  end
end

function Backend:read()
  local prompt = console.colorize(self:prompt(), console.PURPLE)
  if self.multi_line then
    self.input = self.input .. "\n" .. ln.linenoise(prompt .. " ")
  else
    self.input = ln.linenoise(prompt .. " ")
  end
  if self.input:match("%S") and
     self.history_file and
     not self.multi_line
  then
    ln.historyadd(self.input)
    ln.historysave(self.history_file)
  end
  return self.input
end

function Backend:set_multiline(bool)
  self.multi_line = bool
  ln.setmultiline(bool)
end

return Backend
