-- imports

local NuiText = require("nui.text")
local Job = require("plenary.job")

local lib_buf = require("ollama.lib.buffer")
local layout_create = require("ollama.layout.create")

local M = {}

-- connection info

local ollama_port = 11434
local ollama_url = string.format("http://localhost:%s/api/generate", ollama_port)

-- main function

local layout, prompt_popup, result_popup = layout_create.create_default_layout()

local main = function()
    layout:mount()

    vim.api.nvim_buf_call(prompt_popup.bufnr, function() vim.cmd("startinsert") end)

    local job
    local exit_state_text = "Generation Complete"

    local create_job = function(prompt)
        result_popup.border:set_text("bottom", NuiText("generating...", "@lsp.type.parameter"))
        vim.api.nvim_buf_set_lines(result_popup.bufnr, 0, -1, false, {})

        local parameters = {
            model = "codellama",
            prompt = prompt,
            -- stream = false,
        }

        local pending_json_string = ""

        return Job:new({
            command = "curl",
            args = { "-X", "POST", ollama_url, "-d", vim.json.encode(parameters) },
            on_stdout = function(_, data)
                pending_json_string = pending_json_string .. data
                local ok, decoded = pcall(vim.json.decode, pending_json_string)

                if ok then
                    pending_json_string = ""

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
                        function()
                            lib_buf.append_str_to_end_of_buffer(
                                result_popup.bufnr,
                                decoded.response
                            )
                        end
                    )
                end
            end,
            on_exit = function()
                vim.schedule(function() result_popup.border:set_text("bottom", exit_state_text) end)
            end,
        })
    end

    -- shared popup functions
    local close = function()
        if job then job:shutdown() end
        layout:unmount()
    end

    -- prompt popup functions
    local generate = function()
        local prompt_popup_lines = vim.api.nvim_buf_get_lines(prompt_popup.bufnr, 0, -1, false)
        local prompt = table.concat(prompt_popup_lines, "\n")
        job = create_job(prompt)
        job:start()
    end
    local switch_to_result_popup = function() vim.api.nvim_set_current_win(result_popup.winid) end

    -- result popup functions
    local switch_to_prompt_popup = function() vim.api.nvim_set_current_win(prompt_popup.winid) end
    local interupt = function()
        job:shutdown()
        exit_state_text = NuiText("User Interupted", "GruvboxRedBold")
    end

    -- prompt prompt mappings
    prompt_popup:map("i", "<C-S>", function()
        vim.api.nvim_input("<Esc>")
        generate()
    end, {})
    prompt_popup:map("s", "<C-S>", function()
        vim.api.nvim_input("<Esc>")
        generate()
    end, {})

    prompt_popup:map("n", "<CR>", generate, {})
    prompt_popup:map("n", "<Tab>", switch_to_result_popup, {})
    prompt_popup:map("n", "q", close, {})

    -- result popup mappings
    result_popup:map("n", "<Tab>", switch_to_prompt_popup, {})
    result_popup:map("n", "<Esc>", interupt, {})
    result_popup:map("n", "q", close, {})
end

vim.keymap.set("n", "<A-p>", function() main() end, {})

return M
