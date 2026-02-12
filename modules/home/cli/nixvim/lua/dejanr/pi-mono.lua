-- luacheck: globals vim
local vim = vim

local M = {}

M.config = {
  pane_target = nil,
}

local function get_current_tmux_session()
  local pane_id = vim.env.TMUX_PANE
  if not pane_id then
    return nil
  end
  local cmd = string.format("tmux display-message -p -t '%s' '#{session_name}' 2>/dev/null", pane_id)
  local handle = io.popen(cmd)
  if not handle then
    return nil
  end
  local session = handle:read("*a"):gsub("%s+$", "")
  handle:close()
  return session ~= "" and session or nil
end

local function find_pi_pane()
  local session = get_current_tmux_session()
  if not session then
    vim.notify("Not running inside a tmux session", vim.log.levels.WARN)
    return nil
  end

  local cmd = string.format(
    "tmux list-panes -s -t '%s' -F '#{session_name}:#{window_index}.#{pane_index}\t#{pane_current_command}' 2>/dev/null",
    session
  )
  local handle = io.popen(cmd)
  if not handle then
    return nil
  end

  local output = handle:read("*a")
  handle:close()

  for line in output:gmatch("[^\n]+") do
    local target, pane_cmd = line:match("^([^\t]+)\t(.+)$")
    if target and pane_cmd and pane_cmd:match("^pi$") then
      return target
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

local function send_to_tmux(target, text)
  -- Clear any existing input in pi-mono first (Ctrl+A select all, then delete)
  os.execute(string.format("tmux send-keys -t '%s' C-a C-k", target))

  -- Use 3-step bracketed paste so pi treats content as pasted text,
  -- not keystrokes (avoids triggering shortcuts like backtick for voice input).
  -- Step 1: send bracketed paste start via hex bytes
  os.execute(string.format("tmux send-keys -t '%s' -H 1b 5b 32 30 30 7e", target))

  -- Step 2: paste raw text via temp file (avoids shell escaping issues)
  local tmpfile = os.tmpname()
  local f = io.open(tmpfile, "w")
  if not f then
    vim.notify("Failed to create temp file", vim.log.levels.ERROR)
    return false
  end
  f:write(text)
  f:close()

  local cmd = string.format("tmux load-buffer '%s' \\; paste-buffer -d -t '%s'", tmpfile, target)
  local result = os.execute(cmd)
  os.remove(tmpfile)

  if result ~= 0 then
    vim.notify("Failed to send to tmux pane: " .. target, vim.log.levels.ERROR)
    return false
  end

  -- Step 3: send bracketed paste end via hex bytes
  os.execute(string.format("tmux send-keys -t '%s' -H 1b 5b 32 30 31 7e", target))

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

  local filepath = vim.fn.expand("%:p")

  vim.ui.input({ prompt = "Send to pi: " }, function(input)
    if input == nil then
      vim.notify("Cancelled", vim.log.levels.INFO)
      return
    end

    local file_tag =
      string.format('<file name="%s" lines="%d-%d">\n%s\n</file>', filepath, line_start, line_end, selection)

    local message
    if input ~= "" then
      message = string.format("%s\n\n%s", input, file_tag)
    else
      message = file_tag
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
