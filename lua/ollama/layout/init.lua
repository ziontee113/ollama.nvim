local layout_create = require("ollama.layout.create")

PromptLayout = {}
PromptLayout__index = PromptLayout

function PromptLayout.new()
    local instance = setmetatable({}, PromptLayout)
    local layout, prompt_popup, result_popup = layout_create.create_default_layout()

    instance.layout = layout
    instance.prompt_popup = prompt_popup
    instance.result_popup = result_popup

    return instance
end
