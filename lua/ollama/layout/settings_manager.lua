local ns = vim.api.nvim_create_namespace("ollama_settings_popup")

local highlight_groups = {
    default_value = "GruvboxBlueSign",
    modified_value = "GruvboxOrangeSign",
}

local map = {
    {
        param = "mirostat",
        desc = "Enable Mirostat sampling for controlling perplexity. (default: 0, 0 = disabled, 1 = Mirostat, 2 = Mirostat 2.0)\n\nshortcut: `M`",
        default = 0,
        increment = 1,
        min = 0,
        max = 2,
    },
    {
        param = "mirostat_eta",
        desc = "Influences how quickly the algorithm responds to feedback from the generated text. A lower learning rate will result in slower adjustments, while a higher learning rate will make the algorithm more responsive.",
        default = 0.1,
        increment = 0.1,
        min = 0,
    },
    {
        param = "mirostat_tau",
        desc = "Controls the balance between coherence and diversity of the output. A lower value will result in more focused and coherent text.",
        default = 5.0,
        increment = 0.1,
        min = 0,
    },
    {
        param = "num_ctx",
        desc = "Sets the size of the context window used to generate the next token.\n\nshortcut: `x`",
        default = 2048,
        increment = 512,
        min = 512,
    },
    {
        param = "num_gqa",
        desc = "The number of GQA groups in the transformer layer. Required for some models, for example it is 8 for llama2:70b.",
        default = 1,
        min = 0,
        increment = 1,
    },
    {
        param = "num_gpu",
        desc = "The number of layers to send to the GPU(s). On macOS it defaults to 1 to enable metal support, 0 to disable.\n\nshortcut: `gn`",
        default = 50,
        min = 0,
        increment = 4,
    },
    {
        param = "num_thread",
        desc = "Sets the number of threads to use during computation. By default, Ollama will detect this for optimal performance. It is recommended to set this value to the number of physical CPU cores your system has (as opposed to the logical number of cores).",
        default = 8,
        min = 0,
        increment = 1,
    },
    {
        param = "repeat_last_n",
        desc = "Sets how far back for the model to look back to prevent repetition. (Default: 64, 0 = disabled, -1 = num_ctx)\n\nshortcut: `rn`",
        default = 64,
        increment = 4,
        min = 0,
    },
    {
        param = "repeat_penalty",
        desc = "Sets how strongly to penalize repetitions. A higher value (e.g., 1.5) will penalize repetitions more strongly, while a lower value (e.g., 0.9) will be more lenient.\n\nshortcut: `rp`",
        default = 1.1,
        increment = 0.1,
        min = 0,
    },
    {
        param = "temperature",
        desc = "The temperature of the model. Increasing the temperature will make the model answer more creatively.\n\nshortcut: `T`",
        default = 0.8,
        increment = 0.1,
        min = 0,
    },
    {
        param = "seed",
        desc = "Sets the random number seed to use for generation. Setting this to a specific number will make the model generate the same text for the same prompt.\n\nshortcut: `s`",
        default = 0,
        increment = 1,
        min = 0,
    },
    -- {
    --     param = "stop",
    --     desc = "Sets the stop sequences to use.",
    --     default = "AI assistant:",
    -- },
    {
        param = "tfs_z",
        desc = "Tail free sampling is used to reduce the impact of less probable tokens from the output. A higher value (e.g., 2.0) will reduce the impact more, while a value of 1.0 disables this setting.\n\nshortcut: `tz`",
        default = 1,
        increment = 0.1,
        min = 0,
    },
    {
        param = "num_predict",
        desc = "Maximum number of tokens to predict when generating text. (Default: 128, -1 = infinite generation, -2 = fill context)\n\nshortcut: `gp`",
        default = 128,
        increment = 1,
        min = -2,
    },
    {
        param = "top_k",
        desc = "Reduces the probability of generating nonsense. A higher value (e.g. 100) will give more diverse answers, while a lower value (e.g. 10) will be more conservative. (Default: 40)\n\nshortcut: `tk`",
        default = 40,
        increment = 5,
        min = 0,
    },
    {
        param = "top_p",
        desc = "Works together with top-k. A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text. (Default: 0.9)\n\nshortcut: `tp`",
        default = 0.9,
        increment = 0.05,
        min = 0,
    },
}

local addons = [[


  `d`   default value
<Tab>   `prompt`
  `S`     `system prompt`
  [q]     close layout
]]

SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager.new(settings_popup, description_popup)
    local instance = setmetatable({}, SettingsManager)
    instance.settings_popup = settings_popup
    instance.description_popup = description_popup
    return instance
end

function SettingsManager:init()
    -- insert empty rows
    local empty_rows = {}
    for i, _ in pairs(map) do
        table.insert(empty_rows, "")
        if i < #map then table.insert(empty_rows, "") end
    end
    vim.api.nvim_buf_set_lines(self.settings_popup.bufnr, 0, -1, false, empty_rows)

    -- set extmarks
    local j = 0
    for i, tbl in ipairs(map) do
        vim.api.nvim_buf_set_extmark(self.settings_popup.bufnr, ns, j, 0, {
            virt_text = { { tbl.param, "GruvboxYellowSign" } },
            virt_text_pos = "overlay",
        })

        map[i].line = j
        map[i].value = map[i].default
        map[i].extmark = vim.api.nvim_buf_set_extmark(self.settings_popup.bufnr, ns, j, 0, {
            virt_text = { { tostring(tbl.default), "GruvboxBlueSign" } },
            virt_text_pos = "right_align",
        })

        j = j + 2
    end
end

function SettingsManager:update_extmark_value(index)
    local hl_group = highlight_groups.default_value
    if map[index].value ~= map[index].default then hl_group = highlight_groups.modified_value end

    vim.api.nvim_buf_del_extmark(self.settings_popup.bufnr, ns, map[index].extmark)
    map[index].extmark =
        vim.api.nvim_buf_set_extmark(self.settings_popup.bufnr, ns, map[index].line, 0, {
            virt_text = { { tostring(map[index].value), hl_group } },
            virt_text_pos = "right_align",
        })
end

function SettingsManager:get_setting_index_at_cursor()
    local cursor_line = unpack(vim.api.nvim_win_get_cursor(0))
    local index = math.floor(cursor_line / 2) + 1
    return index
end

function SettingsManager:restore_default_value()
    local index = self:get_setting_index_at_cursor()
    map[index].value = map[index].default
    self:update_extmark_value(index)
end

function SettingsManager:_inc(positive, multiply)
    local index = self:get_setting_index_at_cursor()

    map[index].value = map[index].value + (map[index].increment * positive * multiply)

    if map[index].value < map[index].min then map[index].value = map[index].min end
    if map[index].value > (map[index].max or math.huge) then map[index].value = map[index].max end

    self:update_extmark_value(index)
end

local find_index_from_param = function(param)
    for index, tbl in ipairs(map) do
        if tbl.param == param then return index end
    end
end

function SettingsManager:go_to_param(param)
    local index = find_index_from_param(param)
    if index then
        vim.api.nvim_win_set_cursor(self.settings_popup.winid, { map[index].line + 1, 0 })
        vim.api.nvim_set_current_win(self.settings_popup.winid)
    end
end

function SettingsManager:increment(multiply) self:_inc(1, multiply or 1) end
function SettingsManager:decrement(multiply) self:_inc(-1, multiply or 1) end

function SettingsManager:get_option_parameters()
    local params = {}
    local number_of_modified_params = 0
    for _, tbl in ipairs(map) do
        if tbl.value ~= tbl.default then
            params[tbl.param] = tbl.value
            number_of_modified_params = number_of_modified_params + 1
        end
    end
    if number_of_modified_params == 0 then
        return nil -- if we give the Ollama API an empty option table, it will error 404.
    end
    return params
end

function SettingsManager:update_description()
    local index = self:get_setting_index_at_cursor()
    vim.api.nvim_buf_set_lines(
        self.description_popup.bufnr,
        0,
        -1,
        false,
        vim.split(string.format("**%s**\n\n", map[index].param) .. map[index].desc .. addons, "\n")
    )
end

return SettingsManager
