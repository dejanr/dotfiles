-- luacheck: globals vim
local vim = vim

local M = {}

M.config = {
  pane_target = nil,
}

local function find_pi_pane()
  local cmd = "tmux list-panes -a -F "
    .. "'#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}' 2>/dev/null"
  local handle = io.popen(cmd)
  if not handle then
    return nil
  end

  local output = handle:read("*a")
  handle:close()

  for line in output:gmatch("[^\n]+") do
    local target, pane_cmd = line:match("^(%S+)%s+(.+)$")
    if target and pane_cmd and (pane_cmd:match("pi") or pane_cmd:match("node")) then
      local check_cmd = string.format(
        "tmux capture-pane -p -t '%s' -S -50 2>/dev/null | grep -q 'pi\\|Claude\\|assistant' && echo 'found'",
        target
      )
      local check = io.popen(check_cmd)
      if check then
        local result = check:read("*a")
        check:close()
        if result:match("found") then
          return target
        end
      end
    end
  end

  handle = io.popen("tmux list-sessions -F '#{session_name}' 2>/dev/null")
  if handle then
    local sessions = handle:read("*a")
    handle:close()
    for session in sessions:gmatch("[^\n]+") do
      if session:match("^pi$") or session:match("pi%-") then
        return session .. ":0.0"
      end
    end
  end

  return nil
end

local function get_visual_selection()
  local mode = vim.fn.mode()

  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd("normal! ")
  end

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]

  if start_line == 0 or end_line == 0 then
    return nil, 0, 0
  end

  local lines = vim.fn.getline(start_line, end_line)
  if type(lines) == "string" then
    lines = { lines }
  end

  if #lines == 0 then
    return nil, 0, 0
  end

  local start_col = start_pos[3]
  local end_col = end_pos[3]

  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    lines[1] = string.sub(lines[1], start_col)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  end

  return table.concat(lines, "\n"), start_line, end_line
end

local function escape_for_tmux(text)
  text = text:gsub("\\", "\\\\")
  text = text:gsub("'", "'\\''")
  text = text:gsub(";", "\\;")
  text = text:gsub("%$", "\\$")
  return text
end

local function send_to_tmux(target, text)
  -- Clear any existing input in pi-mono first (Ctrl+A select all, then delete)
  os.execute(string.format("tmux send-keys -t '%s' C-a C-k", target))

  local escaped = escape_for_tmux(text)
  local cmd = string.format("tmux send-keys -t '%s' -l '%s'", target, escaped)
  local result = os.execute(cmd)
  if result ~= 0 then
    vim.notify("Failed to send to tmux pane: " .. target, vim.log.levels.ERROR)
    return false
  end
  os.execute(string.format("tmux send-keys -t '%s' Enter", target))
  return true
end

function M.send_selection()
  local selection, line_start, line_end = get_visual_selection()
  if not selection or selection == "" then
    vim.notify("No selection to send", vim.log.levels.WARN)
    return
  end

  local target = M.config.pane_target or find_pi_pane()
  if not target then
    vim.notify("Could not find pi-mono tmux pane", vim.log.levels.ERROR)
    return
  end

  local filename = vim.fn.expand("%:t")
  local filetype = vim.bo.filetype

  vim.ui.input({ prompt = "Send to pi: " }, function(input)
    if input == nil then
      vim.notify("Cancelled", vim.log.levels.INFO)
      return
    end

    local message
    if input ~= "" then
      message = string.format(
        "%s:\n\n```%s\n%s\n```\n\n(from %s, lines %d-%d)",
        input,
        filetype,
        selection,
        filename,
        line_start,
        line_end
      )
    else
      message = string.format(
        "```%s\n%s\n```\n\n(from %s, lines %d-%d)",
        filetype,
        selection,
        filename,
        line_start,
        line_end
      )
    end

    if send_to_tmux(target, message) then
      local session, window = target:match("^([^:]+):(%d+)")
      if session and window then
        os.execute(string.format("tmux select-window -t '%s:%s'", session, window))
        os.execute(string.format("tmux select-pane -t '%s'", target))
      end
      vim.notify(string.format("Sent to pi-mono (%s)", target), vim.log.levels.INFO)
    end
  end)
end

function M.set_target(target)
  M.config.pane_target = target
  vim.notify("Pi-mono target set to: " .. target, vim.log.levels.INFO)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
