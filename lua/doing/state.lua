local config = require("doing.config")
local utils = require("doing.utils")

local tasks_file = ""

local function import_tasks()
  tasks_file = vim.fn.getcwd()
     .. utils.os_path_separator()
     .. config.options.store.file_name

  local ok, res = pcall(vim.fn.readfile, tasks_file)
  return ok and res or {}
end

local State = {}

State.message = nil
State.view_enabled = true

State.tasks = import_tasks()

-- reloads tasks when directory changes
vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    State.tasks = import_tasks()
    utils.task_modified()
  end,
})

---syncs file tasks with loaded tasks
local function sync()
  if vim.fn.findfile(tasks_file, ".;") ~= "" and #State.tasks == 0 then
    -- if file exists and there are no tasks, delete it
    vim.schedule_wrap(function()
      local success, err, err_name = (vim.uv or vim.loop).fs_unlink(tasks_file)

      if not success then
        utils.notify(tostring(err_name) .. ":" .. tostring(err),
          vim.log.levels.ERROR)
      end
    end)()
  end

  if #State.tasks > 0 and not vim.fn.writefile(State.tasks, tasks_file) then
    utils.notify("error writing to tasks file", vim.log.levels.ERROR)
  end
end

if not config.options.store.sync_tasks then
  vim.api.nvim_create_autocmd("VimLeave", { callback = sync, })
end

function State.add(str, to_front)
  if to_front then
    table.insert(State.tasks, 1, str)
  else
    table.insert(State.tasks, str)
  end
  return config.options.store.sync_tasks and sync()
end

function State.done()
  table.remove(State.tasks, 1)
  return config.options.store.sync_tasks and sync()
end

function State.set(tasks)
  State.tasks = tasks
  vim.notify(tasks_file)
  return config.options.store.sync_tasks and sync()
end

return State
