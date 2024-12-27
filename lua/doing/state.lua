local dir_separator = vim.fn.has("win32") and "\\" or "/"

local State = {}

---@class DoingOptions
---@field ignored_buffers string[]|fun():string[] elements of the array are checked against buffer filename/filetype
---@field message_timeout integer how many millisecons messages will stay on screen
---@field doing_prefix string prefix to show before the task
---@field winbar.enabled boolean if plugin should manage the winbar
---@field store.file_name string name of the task file
---@field store.auto_delete_file boolean auto delete tasks file
---@field show_remaining boolean show "+n more" when there are more than 1 tasks

State.default_opts = {
  message_timeout = 2000,
  doing_prefix = "Doing: ",

  -- doesn"t display on buffers that match filetype/filename/filepath to
  -- entries can be either a string array or a function that returns a
  -- string array filepath can be relative or absolute
  ignored_buffers = { "NvimTree", },

  -- if should append "+n more" to the status when there's tasks remaining
  show_remaining = true,

  -- if plugin should manage the winbar
  winbar = { enabled = false, },

  store = {
    -- name of tasks file
    file_name = ".tasks",
  },
}

State.view_enabled = true
State.tasks = nil
State.message = nil
State.auGroupID = nil
State.options = State.default_opts

---initialize task store
State.init = function(options)
  local default_state = {
    options = options,
    file = nil,
    tasks = {},
  }

  local instance = setmetatable(default_state, { __index = State, })

  local state = require("doing.state")
  vim.api.nvim_create_autocmd("DirChanged", {
    group = state.auGroupID,
    callback = function()
      state.tasks = State.init(state.options.store)
    end,
  })
  instance.tasks = instance:import_file() or {}
  return instance
end

-- creates a file based on configs
function State:create_file()
  local name = State.options.store.file_name
  local cwd = vim.fn.getcwd()
  local file = io.open(cwd .. dir_separator .. name, "w")
  assert(file, "couldn't create " .. name .. " in current cwd: " .. cwd)

  file:write("")
  file:close()

  return cwd .. dir_separator .. name
end

-- finds tasks file in cwd
function State:import_file()
  local file = vim.fn.findfile(vim.fn.getcwd() .. dir_separator .. State.options.store.file_name, ".;")

  if file == "" then
    self.file = nil
  else
    local is_readable = vim.fn.filereadable(file) == 1
    assert(is_readable, string.format("file not %s readable", file))

    self.file = file
  end

  return self.file and vim.fn.readfile(self.file) or nil
end

local function delete_file(file_path)
  vim.schedule_wrap(function()
    local success, err, err_name = (vim.uv or vim.loop).fs_unlink(file_path)

    if not success then
      vim.notify(tostring(err_name) .. ":" .. tostring(err),
        vim.log.levels.ERROR, { title = "doing.nvim: error deleting tasks file", })
    end
  end)()
end

-- syncs file tasks with loaded tasks. creates file if force == true
function State:sync()
  if (not self.file) and #self.tasks > 0 then
    self.file = self:create_file()
  elseif self.file and #self.tasks == 0 then
    delete_file(self.file)
  end

  if self.file and vim.fn.filewritable(self.file) and self.tasks ~= {} then
    local res = vim.fn.writefile(self.tasks, self.file)
    if res ~= 0 then
      vim.notify("error writing to tasks file",
        vim.log.levels.ERROR, { title = "doing.nvim", })
    end
  end

  return self
end

function State:current()
  return self.tasks[1]
end

function State:get()
  return self.tasks
end

function State:set(tasks)
  self.tasks = tasks
  return self:sync()
end

function State:count()
  return #self.tasks
end

function State:add(str, to_front)
  if to_front then
    table.insert(self.tasks, 1, str)
  else
    table.insert(self.tasks, str)
  end

  return self:sync()
end

function State:pop()
  return table.remove(self.tasks, 1), self:sync()
end

return State
