local utils = require("doing.utils")
local dir_separator = utils.get_path_separator()

local State = {}

State.file_name = nil
State.tasks = nil
State.message = nil
State.view_enabled = true
State.auGroupID = nil

---initialize task store
State.init = function(file_name)
  State.file_name = file_name

  local default_state = {
    file = nil,
    tasks = {},
  }

  local instance = setmetatable(default_state, { __index = State, })

  vim.api.nvim_create_autocmd("DirChanged", {
    group = State.auGroupID,
    callback = function()
      State.tasks = State.init(file_name)
    end,
  })

  instance.tasks = instance:import_file() or {}
  return instance
end

-- creates a file based on configs
function State:create_file()
  local name = State.file_name
  local cwd = vim.fn.getcwd()
  local file = io.open(cwd .. dir_separator .. name, "w")
  assert(file, "couldn't create " .. name .. " in current cwd: " .. cwd)

  file:write("")
  file:close()

  return cwd .. dir_separator .. name
end

-- finds tasks file in cwd
function State:import_file()
  local file = vim.fn.findfile(vim.fn.getcwd() .. dir_separator .. State.file_name,
    ".;")

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
      utils.notify(tostring(err_name) .. ":" .. tostring(err), vim.log.levels.ERROR)
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
      utils.notify("error writing to tasks file", vim.log.levels.ERROR)
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
