local utils = require("utils")

local coverage = "false"
if os.getenv("ENABLE_COV") and
  utils.module_available("luacov")
then
  coverage = "true"
end

local command = string.format(
  'echo ": tst\n7 3 *\ndup +\n; tst .\nbye" | make repl coverage="%s" | grep "OK"',
  coverage
)

local handle = io.popen(command)
local result = handle:read("*a")
handle:close()
assert(result:match("%D*42%D*"))
