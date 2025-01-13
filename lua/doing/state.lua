local config = require("doing.config")
local utils = require("doing.utils")

local tasks_file = ""

local State = {
  message = nil,
  view_enabled = true,
  tasks = {},
}

-- reloads tasks when directory changes and on startup
vim.api.nvim_create_autocmd({ "DirChanged", "VimEnter", }, {
  callback = function()
    tasks_file = vim.fn.getcwd()
       .. utils.os_path_separator()
       .. config.options.store.file_name

    local ok, res = pcall(vim.fn.readfile, tasks_file)
    State.tasks = ok and res or {}
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
  table.insert(State.tasks, to_front and 1 or #State.tasks, str)
  return config.options.store.sync_tasks and sync()
end

function State.done()
  table.remove(State.tasks, 1)
  return config.options.store.sync_tasks and sync()
end

function State.set(tasks)
  State.tasks = tasks
  return config.options.store.sync_tasks and sync()
end

return State
