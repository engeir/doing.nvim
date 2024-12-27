local state = require("doing.state")

local global_win = nil
local global_buf = nil

local Edit = {}

--- Get all the tasks currently in the pop up window
local function get_buf_tasks()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local indices = {}

  for _, line in pairs(lines) do
    if line:gsub("%s", "") ~= "" then
      table.insert(indices, line)
    end
  end

  return indices
end

-- creates window
local function get_floating_window()
  local bufnr = vim.api.nvim_create_buf(false, false)

  local width = state.options.edit_win_config.width
  local height = state.options.edit_win_config.height

  -- Get the current screen size
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines

  local default_win_config = {
    width = width,
    height = height,

    relative = "editor",
    col = (screen_width / 2) - (width / 2),
    row = (screen_height / 2) - (height / 2),

    style = "minimal",
    border = "rounded",

    noautocmd = true,
  }

  local win = vim.api.nvim_open_win(bufnr, true,
    vim.tbl_extend("force", default_win_config, state.options.edit_win_config))

  vim.api.nvim_set_option_value("winhl", "Normal:NormalFloat", {})

  return {
    buf = bufnr,
    win = win,
  }
end

-- closes the window
local function close_edit(callback)
  if callback then
    callback(get_buf_tasks())
  end

  vim.api.nvim_win_close(0, true)
  global_win = nil
  global_buf = nil
end

-- opens a float window to manage tasks
function Edit.open_edit(tasks, callback)
  if global_win ~= nil and vim.api.nvim_win_is_valid(global_win) then
    close_edit()
    return
  end

  local win_info = get_floating_window()
  global_win = win_info.win
  global_buf = win_info.buf

  vim.api.nvim_set_option_value("number", true, {})
  vim.api.nvim_set_option_value("swapfile", false, {})
  vim.api.nvim_set_option_value("filetype", "doing_tasks", {})
  vim.api.nvim_set_option_value("buftype", "acwrite", {})
  vim.api.nvim_set_option_value("bufhidden", "delete", {})
  vim.api.nvim_buf_set_name(global_buf, "do-edit")
  vim.api.nvim_buf_set_lines(global_buf, 0, #tasks, false, tasks)

  vim.keymap.set("n", "q", function()
    close_edit(callback)
  end, { buffer = global_buf, })

  vim.keymap.set("n", "<Esc>", function()
    close_edit(callback)
  end, { buffer = global_buf, })

  -- event after tasks from pop up has been written to
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = state.auGroupID,
    buffer = global_buf,
    callback = function()
      local new_todos = get_buf_tasks()
      state.tasks:set(new_todos)
    end,
  })

  vim.api.nvim_create_autocmd("BufModifiedSet", {
    group = state.auGroupID,
    buffer = global_buf,
    callback = function()
      vim.api.nvim_set_option_value("modified", false, {})
    end,
  })
end

return Edit
