local M = {}

function M.find_monorepo_root(bufnr, markers, workspace_dirs)
  local closest_root = vim.fs.root(bufnr, markers)
  if not closest_root then
    return nil
  end

  for _, workspace in ipairs(workspace_dirs or {}) do
    local workspace_pattern = workspace .. "/"
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match(workspace_pattern) then
      local workspace_root = vim.fs.root(bufnr, function(name, path)
        return vim.fn.isdirectory(path .. "/" .. workspace) == 1
          and vim.fn.filereadable(path .. "/" .. workspace .. "/" .. markers[1]) == 1
      end)
      if workspace_root then
        return workspace_root .. "/" .. workspace
      end
    end
  end

  return closest_root
end

return M
