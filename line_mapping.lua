local LineMapping = {}

function LineMapping:new()
  local obj = {
    mapping = {},
  }
  setmetatable(obj, {__index = self})
  return obj
end

function LineMapping:map_target_to_source(tag, source_line_num, target_line_num)
  if not self.mapping[tag] then
    self.mapping[tag] = {}
  end
  self.mapping[tag][target_line_num] = source_line_num
end

function LineMapping:resolve_target(tag, target_line_num)
  local mapping = self.mapping[tag]
  if mapping then
    return mapping[target_line_num]
  end
  return nil
end

return LineMapping
