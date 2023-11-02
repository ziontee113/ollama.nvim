-- imports

local Layout = require("nui.layout")
local Popup = require("nui.popup")
local NuiText = require("nui.text")
local Job = require("plenary.job")

local M = {}

-- connection info

local ollama_port = 11434
local ollama_url = string.format("http://localhost:%s/api/generate", ollama_port)

-- functions

local popup_padding = {
    top = 2,
    bottom = 2,
    left = 3,
    right = 3,
}

local prompt_popup = Popup({
    enter = true,
    border = {
        style = "rounded",
        padding = popup_padding,
        text = {
            top = "Prompt",
        },
    },
})

local result_popup = Popup({
    focusable = true,
    border = {
        padding = popup_padding,
        style = "rounded",
        text = {
            top = "Result",
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
        wrap = true,
        linebreak = true,
    },
})

local layout = Layout(
    {
        position = "50%",
        size = {
            width = 80,
            height = 40,
        },
    },
    Layout.Box({
        Layout.Box(prompt_popup, { size = "20%" }),
        Layout.Box(result_popup, { size = "80%" }),
    }, { dir = "col" })
)

local append_str_to_end_of_buffer = function(bufnr, str)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local last_line = lines[#lines]
    local new_lines = vim.split(str, "\n")

    vim.api.nvim_buf_set_text(bufnr, #lines - 1, #last_line, #lines - 1, #last_line, new_lines)
end

-- main function

local main = function()
    ------------------------------------------------------------

    layout:mount()
    result_popup.border:set_text("bottom", NuiText("generating...", "@lsp.type.parameter"))

    local job
    local exit_state_text = "Generation Complete"

    local create_job = function(prompt)
        local parameters = {
            model = "zephyr",
            prompt = prompt,
            -- stream = false,
        }

        local half_baked_cake = ""

        return Job:new({
            command = "curl",
            args = { "-X", "POST", ollama_url, "-d", vim.json.encode(parameters) },
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
                        function() append_str_to_end_of_buffer(result_popup.bufnr, decoded.response) end
                    )
                end
            end,
            on_exit = function()
                vim.schedule(function() result_popup.border:set_text("bottom", exit_state_text) end)
            end,
        })
    end

    prompt_popup:map("i", "<C-CR>", function()
        local prompt =
            table.concat(vim.api.nvim_buf_get_lines(prompt_popup.bufnr, 0, -1, false), "\n")
        job = create_job(prompt)
        job:start()
    end, {})

    prompt_popup:map("n", "<CR>", function()
        local prompt =
            table.concat(vim.api.nvim_buf_get_lines(prompt_popup.bufnr, 0, -1, false), "\n")
        job = create_job(prompt)
        job:start()
    end, {})

    prompt_popup:map(
        "n",
        "<Tab>",
        function() vim.api.nvim_set_current_win(result_popup.winid) end,
        {}
    )

    prompt_popup:map("n", "q", function()
        job:shutdown()
        layout:unmount()
    end, {})

    result_popup:map(
        "n",
        "<Tab>",
        function() vim.api.nvim_set_current_win(prompt_popup.winid) end,
        {}
    )

    result_popup:map("n", "<Esc>", function()
        job:shutdown()
        exit_state_text = NuiText("User Interupted", "GruvboxRedBold")
    end, {})

    result_popup:map("n", "q", function()
        job:shutdown()
        layout:unmount()
    end, {})
end

vim.keymap.set("n", "<A-p>", function() main() end, {})

-- return module
return M
-- {{{nvim-execute-on-save}}}
