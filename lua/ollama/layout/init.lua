local NuiText = require("nui.text")
local Job = require("plenary.job")
local curl = require("plenary.curl")

local layout_create = require("ollama.layout.create")
local lib_buf = require("ollama.lib.buffer")

-- refactor later --

local active_layout = "default"
local layout_map = {
    default = {
        relative = "editor",
        position = "50%",
        size = {
            width = "80%",
            height = "80%",
        },
    },
    small = {
        relative = "editor",
        position = "50%",
        size = {
            width = 80,
            height = 48,
        },
    },
}

-- create OllamaLayout class --

OllamaLayout = {}
OllamaLayout.__index = OllamaLayout

function OllamaLayout.new()
    local instance = setmetatable({}, OllamaLayout)
    local layout, prompt_popup, result_popup, settings_popup = layout_create.create_default_layout()

    instance.layout = layout
    instance.prompt_popup = prompt_popup
    instance.result_popup = result_popup
    instance.settings_popup = settings_popup

    instance.model = "zephyr"
    instance.ollama_port = 11434
    instance.ollama_url = string.format("http://localhost:%s/api/generate", instance.ollama_port)
    instance.ollama_models_url = string.format("http://localhost:%s/api/tags", instance.ollama_port)

    instance:_map_shared_keys()
    instance:_map_settings_popup_keys()
    instance:_map_prompt_popup_keys()
    instance:_map_result_popup_keys()

    return instance
end

function OllamaLayout:_prepare_layout_for_generation()
    if vim.fn.mode() == "i" then vim.api.nvim_input("<Esc>") end
    self:_update_result_popup_bottom_text(NuiText("generating...", "GruvboxBlueSign"))
    vim.api.nvim_buf_set_lines(self.result_popup.bufnr, 0, -1, false, {})
    vim.api.nvim_win_set_cursor(self.result_popup.winid, { 1, 1 })
end

-- select model --

function OllamaLayout:get_model_names()
    local res = curl.get(self.ollama_models_url)
    local decoded = vim.json.decode(res.body)

    local models = decoded.models
    local model_names = {}

    for _, model in ipairs(models) do
        table.insert(model_names, model.name)
    end

    return model_names
end
function OllamaLayout:select_model()
    vim.ui.select(self:get_model_names(), {
        prompt = "Select model:",
    }, function(choice)
        self.model = choice
        self:_update_prompt_title(self.model)
    end)
end

-- generation job --

function OllamaLayout:_get_prompt()
    local prompt_popup_lines = vim.api.nvim_buf_get_lines(self.prompt_popup.bufnr, 0, -1, false)
    local prompt = table.concat(prompt_popup_lines, "\n")
    return prompt
end
function OllamaLayout:_create_generation_job(prompt)
    -- refactor this
    local parameters = {
        model = self.model,
        prompt = prompt,
    }

    local pending_json_string = ""

    self.job = Job:new({
        command = "curl",
        args = { "-X", "POST", self.ollama_url, "-d", vim.json.encode(parameters) },
        on_stdout = function(_, data)
            pending_json_string = pending_json_string .. data
            local ok, decoded = pcall(vim.json.decode, pending_json_string)

            if ok then
                pending_json_string = ""

                if decoded.eval_count then
                    local token_per_sec = decoded.eval_count
                        / decoded.eval_duration -- nanoseconds
                        * 1000000000
                    local updated_result_bottom_text = string.format(
                        "Generated: %s tokens | Speed: %s tokens per second",
                        decoded.eval_count,
                        string.format("%.1f", token_per_sec)
                    )

                    self:_update_result_popup_bottom_text(updated_result_bottom_text)
                end

                self:_append_result(decoded.response)
            end
        end,
    })
end
function OllamaLayout:_append_result(str)
    vim.schedule(function() lib_buf.append_str_to_end_of_buffer(self.result_popup.bufnr, str) end)
end

-- layout related methods --

function OllamaLayout:_update_result_popup_bottom_text(text)
    vim.schedule(function() self.result_popup.border:set_text("bottom", text) end)
end
function OllamaLayout:_update_prompt_title(text)
    vim.schedule(function() self.result_popup.border:set_text("top", text, "center") end)
end

function OllamaLayout:toggle_layout()
    local layout = self.layout
    if active_layout == "default" then
        active_layout = "big"
    else
        active_layout = "default"
    end
    layout:update(layout_map[active_layout])
end

-- mapped methods --

function OllamaLayout:generate()
    self:_prepare_layout_for_generation()
    local prompt = self:_get_prompt()
    self:_create_generation_job(prompt)
    self.job:start()
end

function OllamaLayout:interupt()
    if self.job then
        self.job:shutdown()
        self:_update_result_popup_bottom_text(NuiText("User Interupted", "GruvboxRedBold"))
    end
end

function OllamaLayout:switch_to_result_popup() vim.api.nvim_set_current_win(self.result_popup.winid) end
function OllamaLayout:switch_to_prompt_popup() vim.api.nvim_set_current_win(self.prompt_popup.winid) end
function OllamaLayout:switch_to_settings_popup()
    vim.api.nvim_set_current_win(self.settings_popup.winid)
end

-- mappings --

function OllamaLayout:smap(mode, mapping, map_to, opts)
    self.prompt_popup:map(mode, mapping, map_to, opts or {})
    self.result_popup:map(mode, mapping, map_to, opts or {})
    self.settings_popup:map(mode, mapping, map_to, opts or {})
end

function OllamaLayout:_map_shared_keys()
    self:smap("n", "<CR>", function() self:generate() end, {})
    self:smap("n", "q", function() self:hide() end, {})
    self:smap("n", "m", function() self:select_model() end, {})
    self:smap("n", "<C-l>", function() self:toggle_layout() end, {})
    self:smap("n", "s", function() self:switch_to_settings_popup() end, {})
end

function OllamaLayout:_map_settings_popup_keys()
    local popup = self.settings_popup
    popup:map("n", "<Tab>", function() self:switch_to_prompt_popup() end, {})
end

function OllamaLayout:_map_prompt_popup_keys()
    local popup = self.prompt_popup
    popup:map("i", "<C-S>", function() self:generate() end, {})
    popup:map("s", "<C-S>", function() self:generate() end, {})
    popup:map("n", "<Tab>", function() self:switch_to_result_popup() end, {})
end

function OllamaLayout:_map_result_popup_keys()
    local popup = self.result_popup
    popup:map("n", "<Tab>", function() self:switch_to_prompt_popup() end, {})
end

-- public methods --

function OllamaLayout:mount()
    self.mounted = true
    self.layout:mount()
    self:_update_result_popup_bottom_text("waiting for prompt...")
    vim.api.nvim_set_current_win(self.prompt_popup.winid)
    vim.cmd("startinsert")
end

function OllamaLayout:show()
    if not self.mounted then
        self:mount()
    else
        self.layout:show()
    end
end

function OllamaLayout:hide() self.layout:hide() end

return OllamaLayout
