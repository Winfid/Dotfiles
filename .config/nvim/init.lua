vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

local COMMENT_COLUMN = 28

local function align_asm_comments()
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    for i, line in ipairs(lines) do
        -- Skip comment-only lines
        if not line:match("^%s*;") then
            local code, comment = line:match("^(.-)%s*;(.*)")

            if code and code:match("%S") then
                local width = vim.fn.strdisplaywidth(code)

                local padding

                if width < COMMENT_COLUMN then
                    padding = string.rep(
                        " ",
                        COMMENT_COLUMN - width
                    )
                else
                    -- Code is already past the target column
                    padding = "  "
                end

                lines[i] = code .. padding .. ";" .. comment
            end
        end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.asm", "*.s", "*.inc" },
    callback = align_asm_comments,
})
