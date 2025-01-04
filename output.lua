local Output = {}

function Output.new()
  local obj = {lines = {""}}
  setmetatable(obj, {__index = Output})
  return obj
end

function Output:append(str)
  self.lines[self:size()] = self.lines[self:size()] .. str
end

function Output:new_line()
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
    return loadstring(text)
  else -- Since Lua 5.2, loadstring has been replaced by load.
    return load(text)
  end
end

return Output
