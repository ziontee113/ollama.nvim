local OllamaLayout = require("ollama.layout")

local M = {}

local layout = OllamaLayout.new()

local main = function() layout:show() end

vim.keymap.set("n", "<A-p>", function() main() end, {})

return M
