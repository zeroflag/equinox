local Optimizer = {}
local matchers = require("ast_matchers")

function Optimizer.new()
  local obj = {logging = false, enabled = true}
  setmetatable(obj, {__index = Optimizer})
  return obj
end

function Optimizer:enable_logging(bool)
  self.logging = bool
end

function Optimizer:enable(bool)
  self.enabled = bool
end

function Optimizer:log_ast(node)
  --require("tests/json")
  --self:log("AST: " .. to_json_str(node))
end

function Optimizer:log(txt)
  if self.logging then
    print("[OPTI] " .. txt)
  end
end

function Optimizer:optimize_iteratively(ast)
  if not self.enabled then return ast end
  local num_of_optimizations, iterations = 0, 0
  repeat
    ast, num_of_optimizations = self:optimize(ast)
    iterations = iterations + 1
    self:log(string.format(
          "Iteration: %d finished. Number of optimizations: %d",
          iterations, num_of_optimizations))
  until num_of_optimizations == 0
  return ast
end

function Optimizer:optimize(ast)
  local result, i, num_matches = {}, 1, 0
  while i <= #ast do
    local node = ast[i]
    self:log_ast(node)
    local found = false
    for _, matcher in ipairs(matchers) do
      if matcher:matches(ast, i) then
        matcher.logging = self.logging
        matcher:optimize(ast, i, result)
        i = i + matcher:size()
        num_matches = num_matches + 1
        found = true
      end
    end
    if not found then
      table.insert(result, node)
      i = i + 1
    end
  end
  return result, num_matches
end

return Optimizer
