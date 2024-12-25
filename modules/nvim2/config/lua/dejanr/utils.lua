local M = {}

M.ToggleQF = function()
  for _, win in pairs(vim.fn.getwininfo()) do
    if win['quickfix'] == 1 then
      vim.cmd 'cclose'
      return
    end
  end
  if not vim.tbl_isempty(vim.fn.getqflist()) then
    vim.cmd 'copen'
  end
end

M.ToggleLocList = function()
  for _, win in pairs(vim.fn.getwininfo()) do
    if win['loclist'] == 1 then
      vim.cmd 'lclose'
      return
    end
  end
  if not vim.tbl_isempty(vim.fn.getloclist(0)) then
    vim.cmd 'lopen'
  end
end

return M
