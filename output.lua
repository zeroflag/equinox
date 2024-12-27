local Output = {}

function Output.new()
  local obj = {buffer = {}}
  setmetatable(obj, {__index = Output})
  return obj
end

function Output.append(self, str)
  table.insert(self.buffer, str)
end

function Output.cr(self)
  self:append("\n")
end

function Output.text(self)
  return table.concat(self.buffer)
end

function Output.load(self)
  local text = self:text()
  if loadstring then
    loadstring(text)()
  else -- Since Lua 5.2, loadstring has been replaced by load.
    load(text)()
  end
end

return Output
