local console = require("console")

local Backend = {}

function Backend:new()
  local obj = {input = ""}
  setmetatable(obj, {__index = self})
  return obj
end

function Backend:prompt()
  if self.multi_line then
    return "..."
  else
    return "#"
  end
end

function Backend:save_history(input)
  -- unsupported
end

function Backend:read()
  console.message(self:prompt() .. " ", console.PURPLE, true)
  if self.multi_line then
    self.input = self.input .. "\n" .. io.read()
  else
    self.input = io.read()
  end
  return self.input
end

function Backend:set_multiline(bool)
  self.multi_line = bool
end

return Backend
