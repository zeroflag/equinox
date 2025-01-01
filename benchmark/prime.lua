local function sieve_of_eratosthenes(limit)
  local primes = {}
  for i = 2, limit do primes[i] = true end
  for i = 2, math.sqrt(limit) do
    if primes[i] then
      for j = i * i, limit, i do
        primes[j] = false
      end
    end
  end
  local result = {}
  for i = 2, limit do
    if primes[i] then
      table.insert(result, i)
    end
  end
  return result
end

local started = os.clock()
local result = sieve_of_eratosthenes(1000000)
print(os.clock() - started)

for k,v in pairs(result) do
  print(k .. " " .. v .. " ")
end
