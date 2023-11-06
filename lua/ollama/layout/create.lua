local Layout = require("nui.layout")
local Popup = require("nui.popup")

local M = {}

local popup_padding = {
    top = 2,
    bottom = 2,
    left = 3,
    right = 3,
}

local create_default_prompt_popup = function()
    return Popup({
        enter = true,
        border = {
            style = "rounded",
            padding = popup_padding,
            text = {
                top = "Prompt",
            },
        },
        buf_options = {
            filetype = "ollama_prompt",
        },
    })
end

local create_default_result_popup = function()
    return Popup({
        focusable = true,
        border = {
            padding = popup_padding,
            style = "rounded",
            text = {
                top = "Result",
                top_align = "center",
                bottom = "Standby",
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
end

local create_settings_popup = function()
    return Popup({
        enter = true,
        border = {
            style = "rounded",
            padding = popup_padding,
            text = {
                top = "Settings",
            },
        },
        buf_options = {
            filetype = "ollama_configuration",
        },
    })
end

M.create_default_layout = function()
    local prompt_popup = create_default_prompt_popup()
    local result_popup = create_default_result_popup()
    local settings_popup = create_settings_popup()

    local layout = Layout(
        {
            relative = "editor",
            position = "50%",
            size = {
                width = "80%",
                height = "80%",
            },
        },
        Layout.Box({
            Layout.Box({
                Layout.Box(prompt_popup, { size = "20%" }),
                Layout.Box(result_popup, { size = "80%" }),
            }, { size = "80%", dir = "col" }),
            Layout.Box(settings_popup, { size = "20%" }),
        }, { dir = "row" })
    )

    return layout, prompt_popup, result_popup, settings_popup
end

return M
