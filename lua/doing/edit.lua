local config = require("doing.config")

local Edit = {}

Edit.win = nil
Edit.buf = nil

---get a tasks table from the buffer lines
local function get_buf_tasks()
  local tasks = {}

  if Edit.buf then
    local lines = vim.api.nvim_buf_get_lines(Edit.buf, 0, -1, true)

    for _, line in pairs(lines) do
      -- checks if line is just spaces
      if line:gsub("%s", "") ~= "" then
        table.insert(tasks, line)
      end
    end
  end

  return tasks
end

---creates window
local function setup_floating_window()
  Edit.buf = vim.api.nvim_create_buf(false, false)

  local width = config.options.edit_win_config.width
  local height = config.options.edit_win_config.height

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

  Edit.win = vim.api.nvim_open_win(Edit.buf, true,
    vim.tbl_extend("force", default_win_config, config.options.edit_win_config))
end

---closes the window
local function close_edit(callback)
  if callback then
    callback(get_buf_tasks())
  end

  if Edit.win then
    vim.api.nvim_win_close(Edit.win, true)
    Edit.win = nil
  end
end

---@brief open floating window to edit tasks
---@param state table current state of doing.nvim
---@param callback function callback to run after closing the window
function Edit.open_edit(state, callback)
  if Edit.win then
    return close_edit()
  end

  setup_floating_window()

  vim.api.nvim_set_option_value("number", true, {})
  vim.api.nvim_set_option_value("swapfile", false, {})
  vim.api.nvim_set_option_value("filetype", "doing_tasks", {})
  vim.api.nvim_set_option_value("bufhidden", "delete", {})
  vim.api.nvim_buf_set_name(Edit.buf, "do-edit")

  vim.api.nvim_buf_set_lines(Edit.buf, 0, state.tasks:count(), false, state.tasks:get())


  local function finish(new_todos)
    state.tasks:set(new_todos)
    callback()
  end

  vim.keymap.set("n", "q", function() close_edit(finish) end, { buffer = Edit.buf, })
  vim.keymap.set("n", "<Esc>", function() close_edit(finish) end, { buffer = Edit.buf, })

  -- save tasks when buffer is written
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = state.auGroupID,
    buffer = Edit.buf,
    callback = function()
      local new_todos = get_buf_tasks()
      state.tasks:set(new_todos)
    end,
  })
end

return Edit
