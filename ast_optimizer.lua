local Optimizer = {}
local matchers = require("ast_matchers")

function Optimizer.new(logging)
  local obj = {logging = logging}
  setmetatable(obj, {__index = Optimizer})
  return obj
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

    if "code_seq" == node.name then
      for _, code in ipairs(node.code) do
        table.insert(result, code)
      end
      i = i + 1
    else
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
  end
  return result, num_matches
end

return Optimizer
