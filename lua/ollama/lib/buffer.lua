local M = {}

M.append_str_to_end_of_buffer = function(bufnr, str)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local last_line = lines[#lines]
    local new_lines = vim.split(str, "\n")

    vim.api.nvim_buf_set_text(bufnr, #lines - 1, #last_line, #lines - 1, #last_line, new_lines)
end

return M
