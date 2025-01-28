package = "equinox"
version = "0.0-0"

source = {
  url = "git+https://github.com/zeroflag/equinox",
  tag = "v0.1-5"
}

description = {
  summary = "Forth Dialect",
  detailed = [[
Equinox is a Forth programming language that compiles to Lua.
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
