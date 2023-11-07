local NuiText = require("nui.text")
local Job = require("plenary.job")
local curl = require("plenary.curl")

local layout_create = require("ollama.layout.create")
local SettingsManager = require("ollama.layout.settings_manager")
local description_autocmds = require("lua.ollama.layout.description_autocmds")
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
    full = {
        relative = "editor",
        position = "50%",
        size = {
            width = "90%",
            height = "90%",
        },
    },
}

-- create OllamaLayout class --

OllamaLayout = {}
OllamaLayout.__index = OllamaLayout

function OllamaLayout.new()
    local instance = setmetatable({}, OllamaLayout)
    local layout, prompt_popup, result_popup, settings_popup, description_popup, system_prompt_popup =
        layout_create.create_default_layout()

    instance.layout = layout
    instance.system_prompt_popup = system_prompt_popup
    instance.prompt_popup = prompt_popup
    instance.result_popup = result_popup
    instance.settings_popup = settings_popup
    instance.description_popup = description_popup

    instance.last_active_popup = prompt_popup

    instance.model = "zephyr"
    instance.ollama_port = 11434
    instance.ollama_url = string.format("http://localhost:%s/api/generate", instance.ollama_port)
    instance.ollama_models_url = string.format("http://localhost:%s/api/tags", instance.ollama_port)

    instance:_map_shared_keys()
    instance:_map_system_prompt_popup_keys()
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
        self:_update_result_popup_title(self.model)
    end)
end

-- generation job --

function OllamaLayout:_get_system_prompt()
    local system_prompt_popup_lines =
        vim.api.nvim_buf_get_lines(self.system_prompt_popup.bufnr, 0, -1, false)
    local system_prompt = table.concat(system_prompt_popup_lines, "\n")
    if #system_prompt == 0 then return nil end
    return system_prompt
end
function OllamaLayout:_get_prompt()
    local prompt_popup_lines = vim.api.nvim_buf_get_lines(self.prompt_popup.bufnr, 0, -1, false)
    local prompt = table.concat(prompt_popup_lines, "\n")
    return prompt
end
function OllamaLayout:_create_generation_job(prompt, system_prompt)
    local options = self.settings_manager:get_option_parameters()
    local parameters = {
        model = self.model,
        prompt = prompt,
        options = options,
        system = system_prompt,
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
function OllamaLayout:_update_result_popup_title(text)
    vim.schedule(function() self.result_popup.border:set_text("top", text, "center") end)
end

function OllamaLayout:toggle_layout()
    local layout = self.layout
    if active_layout == "default" then
        active_layout = "full"
    else
        active_layout = "default"
    end
    layout:update(layout_map[active_layout])
end

-- mapped methods --

function OllamaLayout:generate()
    self:_prepare_layout_for_generation()
    local prompt = self:_get_prompt()
    local system_prompt = self:_get_system_prompt()
    self:_create_generation_job(prompt, system_prompt)
    self.job:start()
end

function OllamaLayout:interupt()
    if self.job then
        self.job:shutdown()
        self:_update_result_popup_bottom_text(NuiText("User Interupted", "GruvboxRedBold"))
    end
end

function OllamaLayout:switch_to_system_prompt_popup()
    self.last_active_popup = self.system_prompt_popup
    vim.api.nvim_set_current_win(self.system_prompt_popup.winid)
end
function OllamaLayout:switch_to_result_popup()
    self.last_active_popup = self.result_popup
    vim.api.nvim_set_current_win(self.result_popup.winid)
end
function OllamaLayout:switch_to_prompt_popup()
    self.last_active_popup = self.prompt_popup
    vim.api.nvim_set_current_win(self.prompt_popup.winid)
end
function OllamaLayout:switch_to_settings_popup()
    self.last_active_popup = self.setttings_popup
    vim.api.nvim_set_current_win(self.settings_popup.winid)
end

function OllamaLayout:update_description(lines)
    vim.api.nvim_buf_set_lines(self.description_popup.bufnr, 0, -1, false, lines)
end

-- mappings --

function OllamaLayout:smap(mode, mapping, map_to, opts)
    self.prompt_popup:map(mode, mapping, map_to, opts or {})
    self.result_popup:map(mode, mapping, map_to, opts or {})
    self.settings_popup:map(mode, mapping, map_to, opts or {})
    self.system_prompt_popup:map(mode, mapping, map_to, opts or {})
end

function OllamaLayout:_map_shared_keys()
    self:smap("n", "<CR>", function() self:generate() end, {})
    self:smap("n", "q", function() self:hide() end, {})
    self:smap("n", "m", function() self:select_model() end, {})
    self:smap("n", "<C-c>", function() self:interupt() end, {})
    self:smap("n", "<C-l>", function() self:toggle_layout() end, {})

    self:smap("n", "M", function() self.settings_manager:go_to_param("mirostat") end, {})
    self:smap("n", "x", function() self.settings_manager:go_to_param("num_ctx") end, {})
    self:smap("n", "rn", function() self.settings_manager:go_to_param("repeat_last_n") end, {})
    self:smap("n", "rp", function() self.settings_manager:go_to_param("repeat_penalty") end, {})
    self:smap(
        "n",
        "T",
        function() self.settings_manager:go_to_param("temperature") end,
        { nowait = true }
    )
    self:smap("n", "s", function() self.settings_manager:go_to_param("seed") end, {})
    self:smap("n", "gp", function() self.settings_manager:go_to_param("num_predict") end, {})
    self:smap("n", "tz", function() self.settings_manager:go_to_param("tfs_z") end, {})
    self:smap("n", "tp", function() self.settings_manager:go_to_param("top_p") end, {})
    self:smap("n", "tk", function() self.settings_manager:go_to_param("top_k") end, {})
    self:smap(
        "n",
        "gn",
        function() self.settings_manager:go_to_param("num_gpu") end,
        { nowait = true }
    )

    self:smap("n", "S", function() self:switch_to_system_prompt_popup() end, {})
end

function OllamaLayout:_map_system_prompt_popup_keys()
    local popup = self.system_prompt_popup
    popup:map("n", "<Tab>", function() self:switch_to_prompt_popup() end, {})
end

function OllamaLayout:_map_settings_popup_keys()
    local popup = self.settings_popup
    popup:map("n", "<Tab>", function() self:switch_to_prompt_popup() end, {})
    popup:map("n", "j", "2j", { noremap = true })
    popup:map("n", "k", "2k", { noremap = true })
    popup:map("n", "l", function() self.settings_manager:increment() end, {})
    popup:map("n", "h", function() self.settings_manager:decrement() end, {})
    popup:map("n", "L", function() self.settings_manager:increment(2) end, {})
    popup:map("n", "H", function() self.settings_manager:decrement(2) end, {})
    popup:map("n", "K", function() self.settings_manager:increment(4) end, {})
    popup:map("n", "J", function() self.settings_manager:decrement(4) end, {})
    popup:map(
        "n",
        "d",
        function() self.settings_manager:restore_default_value() end,
        { nowait = true }
    )
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
    popup:map("n", "<Esc>", function() self:interupt() end, {})
end

-- public methods --

function OllamaLayout:mount()
    self.mounted = true
    self.layout:mount()

    description_autocmds.set(self)

    self:_update_result_popup_title(self.model)
    self:_update_result_popup_bottom_text("waiting for prompt...")
    vim.api.nvim_set_current_win(self.prompt_popup.winid)
    vim.cmd("startinsert")

    self.settings_manager = SettingsManager.new(self.settings_popup, self.description_popup)
    self.settings_manager:init()
end

function OllamaLayout:show()
    if not self.mounted then
        self:mount()
    else
        self.layout:show()
        if self.last_active_popup then
            vim.api.nvim_set_current_win(self.last_active_popup.winid)
        end
    end
end

function OllamaLayout:hide() self.layout:hide() end

return OllamaLayout
