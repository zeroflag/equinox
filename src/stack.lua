local stack
local NIL = {} -- nil cannot be stored in table, use this placeholder
local name = "data-stack"

if table.create then
  stack = table.create(32)
else
  stack = {nil, nil, nil, nil, nil, nil, nil, nil}
end

function push(e)
  if e ~= nil then
    stack[#stack + 1] = e
  else
    stack[#stack + 1] = NIL
  end
end

function push_many(...)
  local args = {...}
  local n = #stack
  for i = 1, #args do
    if args[i] ~= nil then
      stack[n + i] = args[i]
    else
      stack[n + i] = NIL
    end
  end
end

function pop()
  local size = #stack
  if size == 0 then error("Stack underflow: " .. name) end
  local item = stack[size]
  stack[size] = nil
  if item ~= NIL then return item else return nil end
end

function pop2nd()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  local item = stack[n - 1]
  stack[n -1] = stack[n]
  stack[n] = nil
  if item ~= NIL then return item else return nil end
end

function pop3rd()
  local n = #stack
  if n < 3 then error("Stack underflow: " .. name) end
  local item = table.remove(stack, n - 2)
  if item ~= NIL then return item else return nil end
end

function swap()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  stack[n], stack[n - 1] = stack[n - 1], stack[n]
end

function rot()
  local n = #stack
  if n < 3 then error("Stack underflow: " .. name) end
  local new_top = stack[n -2]
  table.remove(stack, n - 2)
  stack[n] = new_top
end

function mrot()
  local n = #stack
  if n < 3 then error("Stack underflow: " .. name) end
  local temp = stack[n]
  stack[n] = nil
  table.insert(stack, n - 2, temp)
end

function over()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  stack[n + 1] = stack[n - 1]
end

function tuck()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  table.insert(stack, n - 1, stack[n])
end

function nip()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  stack[n - 1] = stack[n]
  stack[n] = nil
end

function dup()
  local n = #stack
  if n < 1 then error("Stack underflow: " .. name) end
  stack[n + 1] = stack[n]
end

function dup2()
  local n = #stack
  if n < 2 then error("Stack underflow: " .. name) end
  local tos1 = stack[n]
  local tos2 = stack[n - 1]
  stack[n + 1] = tos2
  stack[n + 2] = tos1
end

function tos()
  local item = stack[#stack]
  if item == nil then error("Stack underflow: " .. name) end
  if item ~= NIL then return item else return nil end
end

function tos2()
  local item = stack[#stack - 1]
  if item == nil then error("Stack underflow: " .. name) end
  if item ~= NIL then return item else return nil end
end

function _and()
  local a, b = pop(), pop()
  push(a and b)
end

function _or()
  local a, b = pop(), pop()
  push(a or b)
end

function _inc()
  local n = #stack
  if n < 1 then error("Stack underflow: " .. name) end
  stack[n] = stack[n] + 1
end

function _neg()
  local n = #stack
  if n < 1 then error("Stack underflow: " .. name) end
  stack[n] = not stack[n]
end

function depth()
  return #stack
end

function pick(index)
  local item = stack[#stack - index]
  if item == nil then error("Stack underflow: " .. name) end
  if item ~= NIL then return item else return nil end
end

return stack
