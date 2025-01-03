local Output = {}

function Output.new()
  local obj = {lines = {""}}
  setmetatable(obj, {__index = Output})
  return obj
end

function Output.append(self, str)
  self.lines[self:size()] = self.lines[self:size()] .. str
end

function Output.new_line(self)
  table.insert(self.lines, "")
end

function Output.size(self)
  return #self.lines
end

function Output.text(self, from)
  return table.concat(self.lines, "\n", from)
end

function Output.load(self)
  local text = self:text()
  if loadstring then
    return loadstring(text)
  else -- Since Lua 5.2, loadstring has been replaced by load.
    return load(text)
  end
end

return Output
