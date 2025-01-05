function babbage()
  local x = 1
  while true do
    x = x + 1
    local squared = x * x
    if squared % 1000000 == 269696 then
      break
    end
  end
  return x
end

local started = os.clock()
for i = 1, 500 do
  babbage()
end
print(os.clock() - started)

print(babbage())
