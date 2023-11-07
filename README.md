# Ollama.nvim - Neovim Plugin to interact with Ollama API 🦙

![Screenshot from 2023-11-08 06-14-42](https://github.com/ziontee113/ollama.nvim/assets/102876811/ede77ff2-9ca4-45b2-bc5b-626d81faaf23)

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

## ♥️ Special Thanks to:

- [jmorganca](https://github.com/jmorganca) for creating [Ollama](https://github.com/jmorganca/ollama/)
- [David-Kunz](https://github.com/David-Kunz) for creating [gen.nvim](https://github.com/David-Kunz/gen.nvim)
- [MunifTanjim](https://github.com/David-Kunz) for creating [nui.nvim](https://github.com/MunifTanjim/nui.nvim/)
