local ns = vim.api.nvim_create_namespace("testing")

vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

local line, col = 0, 0

vim.api.nvim_buf_set_extmark(0, ns, line, col, {
    virt_text = { { "left", "@text.todo" } },
    virt_text_pos = "overlay",
})

vim.api.nvim_buf_set_extmark(0, ns, line, col, {
    virt_text = { { "right", "Error" } },
    virt_text_pos = "right_align",
})

-- {{{nvim-execute-on-save}}}
