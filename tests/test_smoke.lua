local command = 'echo "7 3 * dup + .\nbye" | make repl | grep "OK"'

local handle = io.popen(command)
local result = handle:read("*a")
handle:close()
assert(result:match("^42.*"))
