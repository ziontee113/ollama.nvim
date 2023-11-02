-- imports
local curl = require("plenary.curl")

local M = {}

-- connection info
local ollama_port = 11434
local ollama_url = string.format("http://localhost:%s/api/generate", ollama_port)

-- testing

local test_parameters = {
    model = "zephyr",
    prompt = "in 1 sentence, tell me the distance to the moon.",
}

local request_body = vim.json.encode(test_parameters)

local cmd = string.format("curl -X POST %s -d '%s'", ollama_url, request_body)

local call = function()
    local data_tbl = {}

    local job_id = vim.fn.jobstart(cmd, {
        on_stdout = function(_, data, _)
            for _, str in ipairs(data) do
                N(str)
            end
        end,
        on_exit = function()
            -- TODO:
        end,
    })
end

vim.keymap.set("n", "<A-p>", function() call() end, {})

-- return module
return M
-- {{{nvim-execute-on-save}}}
