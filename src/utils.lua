local utils = {}

function utils.deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[utils.deepcopy(orig_key)] = utils.deepcopy(orig_value)
    end
    setmetatable(copy, utils.deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function utils.home()
  return os.getenv("USERPROFILE") or os.getenv("HOME")
end

function utils.in_home(file)
  return utils.join(utils.home(), file)
end

function utils.values(tbl)
  local vals = {}
  for k, v in pairs(tbl) do
    table.insert(vals, v)
  end
  return vals
end

function utils.extension(filename)
  return filename:match("^.+(%.[^%.]+)$")
end

function utils.join(dir, child)
  if not dir or "" == dir then return child end
  local sep = ""
  if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then
    sep = package.config:sub(1, 1)
  end
  return dir .. sep .. child
end


function utils.exists(filename)
  local file = io.open(filename, "r")
  if file then
    file:close()
    return true
  else
    return false
  end
end

function utils.file_exists_in_any_of(filename, dirs)
  for i, dir in ipairs(dirs) do
    local path = utils.join(dir, filename)
    if utils.exists(path) then
      return path
    end
  end
  return nil
end

function utils.unique(tbl)
  local seen = {}
  local result = {}
  for _, v in ipairs(tbl) do
    if not seen[v] then
      seen[v] = true
      table.insert(result, v)
    end
  end
  return result
end

function utils.keys(tbl)
  local result = {}
  for key, _ in pairs(tbl) do
    table.insert(result, key)
  end
  return result
end

function utils.startswith(str, prefix)
  return string.sub(str, 1, #prefix) == prefix
end

return utils
