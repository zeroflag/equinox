local output = {}
prn = function(s)
  table.insert(output, s)
end

local equinox = require("equinox")
equinox.main({"-e", "4 5 + #( prn 1 )"})

assert(#output == 1)
assert(output[1] == 9)
