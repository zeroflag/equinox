local version = {}

local filename = "src/version/version.txt"

function version.increment()
  local major, minor, patch = version.current:match("^(%d+)%.(%d+)%-(%d+)$")
  if not major or not minor or not patch then
    error("Invalid version format. Expected format: major.minor.patch")
  end
  major = tonumber(major)
  minor = tonumber(minor)
  patch = tonumber(patch) + 1
  version.current = string.format("%d.%d-%d", major, minor, patch)
end

function version.load()
  local file = io.open(filename, "r")
  if not file then
    error("Could not open file: " .. filename)
  end
  version.current = file:read("*line")
  file:close()
  return version
end

function version.save()
  local file = io.open(filename, "w")
  if not file then
    error("Could not open file for writing: " .. filename)
  end
  file:write(version.current .. "\n")
  file:close()
end

if arg and arg[0]:match("version.lua") then
  version.load()
  print("Increasign current version " .. version.current)
  version.increment()
  print("New version " .. version.current)
  version.save()
end

return version
