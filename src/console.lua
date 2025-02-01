local console = {}

local is_windows = (os.getenv("OS") and string.find(os.getenv("OS"), "Windows"))
  or package.config:sub(1,1) == '\\'

console.RED    = "\27[91m"
console.GREEN  = "\27[92m"
console.CYAN   = "\27[1;96m"
console.PURPLE = "\27[1;95m"
console.RESET  = "\27[0m"

function console.message(text, color, no_cr)
  if no_cr then
    new_line = ""
  else
    new_line = "\n"
  end
  if is_windows then
    color = ""
    reset = ""
  else
    reset = console.RESET
  end
  io.write(string.format("%s%s%s%s", color, text, reset, new_line))
end

function console.colorize(text, color)
  if is_windows then
    return text
  else
    return string.format("%s%s%s", color, text, console.RESET)
  end
end

return console
