# Ollama.nvim - Neovim Plugin to interact with Ollama API

image here

## ⚡Quick Start

Using Lazy:

```lua
local your_keymap = "<C-p>"

return {
    "ziontee113/ollama.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    keys = { your_keymap },
    config = function()
        local ollama = require("ollama")
        vim.keymap.set("n", your_keymap, function() ollama.show() end, {})
    end,
}
```
