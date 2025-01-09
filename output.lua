local Output = {}

function Output.new(name)
  local obj = {lines = {""}, line_number = 1, name = name}
  setmetatable(obj, {__index = Output})
  return obj
end

function Output:append(str)
  self.lines[self:size()] = self.lines[self:size()] .. str
end

function Output:new_line()
  self.line_number = self.line_number +1
  table.insert(self.lines, "")
end

function Output:size()
  return #self.lines
end

function Output:text(from)
  return table.concat(self.lines, "\n", from)
end

function Output:load()
  local text = self:text()
  if loadstring then
    return loadstring(text, self.name)
  else -- Since Lua 5.2, loadstring has been replaced by load.
    return load(text, self.name)
  end
end

return Output
