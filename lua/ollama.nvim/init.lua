-- imports

local curl = require("plenary.curl")
local Popup = require("nui.popup")

local M = {}

-- connection info

local ollama_port = 11434
local ollama_url = string.format("http://localhost:%s/api/generate", ollama_port)

-- testing

local test_parameters = {
    model = "zephyr",
    prompt = "calculate distance in python using numpy",
}

local request_body = vim.json.encode(test_parameters)

local cmd = string.format("curl -X POST %s -d '%s'", ollama_url, request_body)

-- functions

local popup = Popup({
    position = "50%",
    size = {
        width = 80,
        height = 40,
    },
    enter = true,
    focusable = true,
    zindex = 50,
    relative = "editor",
    border = {
        padding = {
            top = 2,
            bottom = 2,
            left = 3,
            right = 3,
        },
        style = "rounded",
        text = {
            top = " I am top title ",
            top_align = "center",
            bottom = "I am bottom title",
            bottom_align = "left",
        },
    },
    buf_options = {
        modifiable = true,
        readonly = false,
        filetype = "markdown",
    },
    win_options = {
        winblend = 10,
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        wrap = true,
        linebreak = true,
    },
})

local append_str_to_end_of_buffer = function(bufnr, str)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local last_line = lines[#lines]
    local new_lines = vim.split(str, "\n")

    vim.api.nvim_buf_set_text(bufnr, #lines - 1, #last_line, #lines - 1, #last_line, new_lines)
end

local call = function()
    popup:mount()

    local job_id = vim.fn.jobstart(cmd, {
        on_stdout = function(_, data, _)
            for _, json_str in ipairs(data) do
                local ok, decoded = pcall(vim.json.decode, json_str)
                if ok then append_str_to_end_of_buffer(popup.bufnr, decoded.response) end
            end
        end,
        on_exit = function()
            -- TODO:
        end,
    })
end

vim.keymap.set("n", "<A-p>", function() call() end, {})

-- return module
return M
-- {{{nvim-execute-on-save}}}
