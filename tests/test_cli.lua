local output = {}
print = function(s)
  table.insert(output, s)
end

local equinox = require("equinox")
equinox.main({"-e", "4 5 + #( print 1 )"})

assert(#output == 1)
assert(output[1] == 9)

output = {}
equinox.main({"-o0", "-e", "2 3 * #( print 1 )"})
assert(#output == 1)
assert(output[1] == 6)

output = {}
equinox.main({"-h"})
