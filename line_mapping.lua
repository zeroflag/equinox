local LineMapping = {}

function LineMapping.new(name)
  local obj = {
    name = name,
    target_source = {},
  }
  setmetatable(obj, {__index = LineMapping})
  return obj
end

function LineMapping:set_target_source(source_line_num, target_line_num)
  self.target_source[target_line_num] = source_line_num
end

function LineMapping:resolve_target(target_line_num)
  return self.target_source[target_line_num]
end


return LineMapping
