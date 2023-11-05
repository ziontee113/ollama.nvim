local NuiText = require("nui.text")
local Job = require("plenary.job")

local layout_create = require("ollama.layout.create")
local lib_buf = require("ollama.lib.buffer")

-- handle this in seperate configuration file later
local ollama_model = "zephyr"
local ollama_port = 11434
local ollama_url = string.format("http://localhost:%s/api/generate", ollama_port)

OllamaLayout = {}
OllamaLayout__index = OllamaLayout

function OllamaLayout.new()
    local instance = setmetatable({}, OllamaLayout)
    local layout, prompt_popup, result_popup = layout_create.create_default_layout()

    instance.layout = layout
    instance.prompt_popup = prompt_popup
    instance.result_popup = result_popup

    instance._map_prompt_popup_keys()
    instance._map_result_popup_keys()

    return instance
end

function OllamaLayout:generate()
    if vim.fn.mode() == "i" then vim.api.nvim_input("<Esc>") end

    self:_update_result_popup_bottom_text(NuiText("generating...", "GruvboxBlueSign"))
    vim.api.nvim_buf_set_lines(self.result_popup.bufnr, 0, -1, false, {})

    local prompt_popup_lines = vim.api.nvim_buf_get_lines(self.prompt_popup.bufnr, 0, -1, false)
    local prompt = table.concat(prompt_popup_lines, "\n")

    local parameters = {
        model = ollama_model,
        prompt = prompt,
    }

    local pending_json_string = ""

    self.job = Job:new({
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
                    self.result_bottom_text = string.format(
                        "Generated: %s tokens | Speed: %s tokens per second",
                        decoded.eval_count,
                        string.format("%.1f", token_per_sec)
                    )
                end

                lib_buf.append_str_to_end_of_buffer(self.result_popup.bufnr, decoded.response)
            end
        end,
    })
end

function OllamaLayout:mount()
    self.layout:mount()
    self:_update_result_popup_bottom_text("waiting for prompt...")
    vim.api.nvim_buf_call(self.prompt_popup.bufnr, function() vim.cmd("startinsert") end)
end

function OllamaLayout:_update_result_popup_bottom_text(text)
    self.result_popup.border:set_text("bottom", text)
end

function OllamaLayout:show() self.layout:show() end
function OllamaLayout:hide() self.layout:hide() end

function OllamaLayout:interupt()
    if self.job then
        self.job:shutdown()
        self._update_result_popup_bottom_text(NuiText("User Interupted", "GruvboxRedBold"))
    end
end

function OllamaLayout:switch_to_result_popup() vim.api.nvim_set_current_win(self.result_popup.winid) end
function OllamaLayout:switch_to_prompt_popup() vim.api.nvim_set_current_win(self.prompt_popup.winid) end

function OllamaLayout:_map_prompt_popup_keys()
    local popup = self.prompt_popup
    popup:map("i", "<C-S>", function() self:generate() end, {})
    popup:map("s", "<C-S>", function() self:generate() end, {})
    popup:map("n", "<CR>", function() self:generate() end, {})
    popup:map("n", "<Tab>", function() self:switch_to_prompt_popup() end, {})
    popup:map("n", "q", function() self:hide() end, {})
end

function OllamaLayout:_map_result_popup_keys()
    local popup = self.result_popup
    popup:map("n", "<Tab>", function() self:switch_to_prompt_popup() end, {})
    popup:map("n", "<Esc>", function() self:interupt() end, {})
    popup:map("n", "q", function() self:hide() end, {})
end
