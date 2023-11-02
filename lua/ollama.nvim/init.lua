-- imports

local Popup = require("nui.popup")
local NuiText = require("nui.text")
local Job = require("plenary.job")

local M = {}

-- connection info

local ollama_port = 11434
local ollama_url = string.format("http://localhost:%s/api/generate", ollama_port)

-- testing

local test_parameters = {
    model = "zephyr",
    prompt = "what's the distance to the moon?",
    -- stream = false,
}

local request_body = vim.json.encode(test_parameters)

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
    local exit_state_text = "Generation Complete"

    popup:mount()
    popup.border:set_text("bottom", NuiText("generating...", "@lsp.type.parameter"))

    local half_baked_cake = ""

    local job = Job:new({
        command = "curl",
        args = { "-X", "POST", ollama_url, "-d", request_body },
        on_stdout = function(_, data)
            half_baked_cake = half_baked_cake .. data

            local ok, decoded = pcall(vim.json.decode, half_baked_cake)

            if ok then
                half_baked_cake = ""

                if decoded.eval_count then
                    local token_per_sec = decoded.eval_count
                        / decoded.eval_duration -- nanoseconds
                        * 1000000000
                    exit_state_text = string.format(
                        "Generated: %s tokens | Speed: %s tokens per second",
                        decoded.eval_count,
                        string.format("%.1f", token_per_sec)
                    )
                end

                vim.schedule(
                    function() append_str_to_end_of_buffer(popup.bufnr, decoded.response) end
                )
            end
        end,
        on_exit = function()
            vim.schedule(function() popup.border:set_text("bottom", exit_state_text) end)
        end,
    })

    job:start()

    popup:map("n", "<Esc>", function()
        job:shutdown()
        exit_state_text = NuiText("User Interupted", "GruvboxRedBold")
    end, {})

    popup:map("n", "q", function()
        job:shutdown()
        popup:unmount()
    end, {})
end

vim.keymap.set("n", "<A-p>", function() call() end, {})

-- return module
return M
-- {{{nvim-execute-on-save}}}
