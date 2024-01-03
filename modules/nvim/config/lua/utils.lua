local M = {}

M.ToggleLocList = function()
    if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
        vim.cmd([[lclose]])
    else
        vim.cmd([[lopen]])
    end
end

return M
