local OllamaLayout = require("ollama.layout")

local M = {}

local layout = OllamaLayout.new()

M.show = function() layout:show() end

return M
