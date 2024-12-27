local err = {}

function err.abort(str)
  error("\27[31mRed Alert:\27[0m " .. str)
end

function err.warn(str)
  print("\27[33mYellow Alert:\27[0m " .. str)
end

return err
