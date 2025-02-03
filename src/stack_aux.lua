local stack = {}
local NIL = {} -- nil cannot be stored in table, use this placeholder
local name = "aux-stack"

function apush(e)
  if e ~= nil then
    stack[#stack + 1] = e
  else
    stack[#stack + 1] = NIL
  end
end

function apop()
  local size = #stack
  if size == 0 then
    error("Stack underflow: " .. name)
  end
  local item = stack[size]
  stack[size] = nil
  if item ~= NIL then return item else return nil end
end

function adepth()
  return #stack
end

return stack
