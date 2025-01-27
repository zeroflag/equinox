local Source = {}

local seq = 1

local function lines_of(input)
  local lines = {}
  for line in input:gmatch("([^\r\n]*)\r?\n?") do
    table.insert(lines, line)
  end
  return lines
end

function Source:new(text, path)
  local obj = {text = text,
               path = path,
               name = nil,
               type = nil,
               lines = lines_of(text)}
  setmetatable(obj, {__index = self})
  if path then
    obj.name = path
    obj.type = "file"
  else
    obj.name = "chunk" .. seq
    seq = seq + 1
    obj.type = "chunk"
  end
  return obj
end

function Source:from_text(text)
  return self:new(text, nil)
end

function Source:empty()
  return self:from_text("")
end

function Source:from_file(path)
  local file = io.open(path, "r")
  if not file then
    error("Could not open file: " .. path)
  end
  local src = self:new(file:read("*a"), path)
  file:close()
  return src
end

function Source:show_lines(src_line_num, n)
  for i = src_line_num - n, src_line_num + n do
    local line = self.lines[i]
    if line then
      local mark = "  "
      if i == src_line_num then mark = "=>" end
      io.stderr:write(string.format("    %s%03d.  %s\n", mark, i , line))
    end
  end
end

return Source
