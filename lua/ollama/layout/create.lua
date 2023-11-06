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
        win_options = {
            wrap = true,
            linebreak = true,
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
            filetype = "ollama_settings",
        },
    })
end

local create_description_popup = function()
    return Popup({
        enter = true,
        border = {
            style = "rounded",
            padding = popup_padding,
            text = {
                top = "Description",
            },
        },
        buf_options = {
            filetype = "markdown",
        },
        win_options = {
            wrap = true,
            linebreak = true,
        },
    })
end

local create_system_prompt_popup = function()
    return Popup({
        enter = true,
        border = {
            style = "rounded",
            padding = popup_padding,
            text = {
                top = "SYSTEM PROMPT",
            },
        },
        buf_options = {
            filetype = "markdown",
        },
        win_options = {
            wrap = true,
            linebreak = true,
        },
    })
end

M.create_default_layout = function()
    local system_prompt_popup = create_system_prompt_popup()
    local prompt_popup = create_default_prompt_popup()
    local result_popup = create_default_result_popup()
    local settings_popup = create_settings_popup()
    local description_popup = create_description_popup()

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
                Layout.Box(system_prompt_popup, { size = "10%" }),
                Layout.Box(prompt_popup, { size = "20%" }),
                Layout.Box(result_popup, { size = "70%" }),
            }, { size = "80%", dir = "col" }),
            Layout.Box({
                Layout.Box(settings_popup, { size = "50%" }),
                Layout.Box(description_popup, { size = "50%" }),
            }, { size = "20%", dir = "col" }),
        }, { dir = "row" })
    )

    return layout,
        prompt_popup,
        result_popup,
        settings_popup,
        description_popup,
        system_prompt_popup
end

return M
