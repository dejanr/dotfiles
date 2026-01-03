local M = {}

function M.find_monorepo_root(bufnr, markers, workspace_dirs)
  local closest_root = vim.fs.root(bufnr, markers)
  if not closest_root then
    return nil
  end

  -- For monorepos, we want to use the root where tsconfig.json lives
  -- This handles cases where individual packages don't have their own tsconfig
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  for _, workspace in ipairs(workspace_dirs or {}) do
    local workspace_pattern = "/" .. workspace .. "/"
    if bufname:match(workspace_pattern) then
      -- Find the monorepo root (parent of the workspace directory)
      local monorepo_root = vim.fs.root(bufnr, function(name, path)
        return vim.fn.isdirectory(path .. "/" .. workspace) == 1
      end)
      if monorepo_root then
        -- Check if root has tsconfig.json, use that for better path resolution
        if vim.fn.filereadable(monorepo_root .. "/tsconfig.json") == 1 then
          return monorepo_root
        end
        -- Otherwise check if the workspace folder has the marker
        for _, marker in ipairs(markers) do
          if vim.fn.filereadable(monorepo_root .. "/" .. workspace .. "/" .. marker) == 1 then
            return monorepo_root .. "/" .. workspace
          end
        end
        -- Fall back to monorepo root if it has any marker
        for _, marker in ipairs(markers) do
          if vim.fn.filereadable(monorepo_root .. "/" .. marker) == 1
            or vim.fn.isdirectory(monorepo_root .. "/" .. marker) == 1 then
            return monorepo_root
          end
        end
      end
    end
  end

  return closest_root
end

return M
