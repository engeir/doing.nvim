local Config = {}

---@class DoingOptions
---@field ignored_buffers string[]|fun():string[] elements are checked against buffer filetype/filename/filepath
---@field message_timeout integer how many millisecons messages will stay on status
---@field doing_prefix string prefix to show before the task
---@field winbar.enabled boolean if plugin should manage the winbar
---@field store.file_name string name of the task file
---@field store.auto_delete_file boolean auto delete tasks file
---@field show_remaining boolean show "+n more" when there are more than 1 tasks
---@field edit_win_config vim.api.keyset.win_config window configs of the floating editor

Config.default_opts = {
  message_timeout = 2000,
  doing_prefix = "Doing: ",

  -- doesn"t display on buffers that match filetype/filename/filepath to
  -- entries. can be either a string array or a function that returns a
  -- string array. filepath can be relative to cwd or absolute
  ignored_buffers = { "NvimTree", },

  -- if should append "+n more" to the status when there's tasks remaining
  show_remaining = true,

  -- window configs of the floating tasks editor
  -- see :h nvim_open_win() for available options
  edit_win_config = {
    width = 50,
    height = 15,

    relative = "editor",
    col = (vim.o.columns / 2) - (50 / 2),
    row = (vim.o.lines / 2) - (15 / 2),

    style = "minimal",
    border = "rounded",

    noautocmd = true,
  },

  -- if plugin should manage the winbar
  winbar = { enabled = true, },

  store = {
    -- name of tasks file
    file_name = ".tasks",
  },
}

Config.options = Config.default_opts

return Config
