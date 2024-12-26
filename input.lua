local Input = {}

function Input.new(source)
  local obj = {index = 1, source = source}
  setmetatable(obj, {__index = Input})
  return obj
end

function Input.parse(self)
  local token = ""
  local begin_str = false
  local stop = false
  while not self:ended() and not stop do
    local chr = self:next()
    if self:is_quote(chr) then
      if begin_str then
        stop = true
      else
        begin_str = true
      end
    end
    if self:is_whitespace(chr) and not begin_str then
      if #token > 0 then
        stop = true
      end
    else
      token = token .. chr
    end
  end
  return token, (begin_str and "string" or "word")
end

function Input.is_quote(self, chr)
  return chr:match('"')
end

function Input.is_whitespace(self, chr)
  return chr:match("%s")
end

function Input.next(self)
  local chr = self.source:sub(self.index, self.index)
  self.index = self.index + 1
  return chr
end

function Input.ended(self)
  return self.index > #self.source
end

return Input
