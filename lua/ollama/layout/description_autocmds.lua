local event = require("nui.utils.autocmd").event

local M = {}

local descriptions = {
    prompt_popup = [[
<Tab> `result`
 <CR> generate
 
  [S]   `system prompt`
]],
    system_prompt_popup = [[
<Tab> `prompt`
 <CR> generate
]],
    result_popup = [[
<Tab> `prompt`
 <CR> generate
<Esc> interupt
  `q`   close layout
  `S`   `system prompt`
  `?`   show settings keymaps
]],
}

local addons = [[

  [m]   change model
<C-l> resize layout
  [q]   close layout

  `M`  mirostat
  `x`  num_ctx
 `gn`  num_gpt
 `rn`  repeat_last_n 
 `rp`  repeat_penalty
  `T`  temperature
  `s`  seed
 `gp`  num_predict
 `tz`  tfs_z
 `tp`  top_p
 `tk`  top_k
]]

M.set = function(ollama_layout)
    ollama_layout.settings_popup:on(
        { event.CursorMoved },
        function() ollama_layout.settings_manager:update_description() end,
        {}
    )

    for key, desc in pairs(descriptions) do
        ollama_layout[key]:on({ event.BufEnter }, function()
            local lines = vim.split(desc .. addons, "\n")
            ollama_layout:update_description(lines)
        end, {})
    end
end

return M
