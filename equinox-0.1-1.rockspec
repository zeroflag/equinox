package = "equinox"
version = "0.1-1"

source = {
  url = "git+https://github.com/zeroflag/equinox",
  tag = "v0.1"
}

description = {
  summary = "Equinox Forth dialect",
  detailed = [[
Equinox is a Forth dialect implemented in Lua. It is designed for simplicity, flexibility, and to be easily embedded in Lua projects.
  ]],
  homepage = "https://github.com/zeroflag/equinox",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1"
}

build = {
  type = "builtin",
  modules = {
    ["equinox_bundle"] = "src/equinox_bundle.lua",
  },
  install = {
    bin = {
      "equinox",
    },
  },
  copy_directories = {
    "ext"
  }
}
