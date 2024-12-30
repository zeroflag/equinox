local err = {}

function err.abort(str)
  error("Red Alert: " .. str)
end

function err.warn(str)
  print("Yellow Alert: " .. str)
end

return err
