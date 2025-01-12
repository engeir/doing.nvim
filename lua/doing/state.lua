local config = require("doing.config")
local utils = require("doing.utils")
local separator = utils.get_path_separator()

local State = {}

State.file = nil
State.message = nil
State.view_enabled = true
State.file_name = config.options.store.file_name

---finds tasks file in cwd
local function import_file()
  local file = vim.fn.findfile(vim.fn.getcwd() .. separator .. State.file_name, ".;")

  if file == "" then
    State.file = nil
  else
    assert(vim.fn.filereadable(file), file .. ": file not found or not readable")
    State.file = file
  end

  return State.file and vim.fn.readfile(State.file) or {}
end

State.tasks = import_file()

vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    State.tasks = import_file()
    utils.task_modified()
  end,
})

---syncs file tasks with loaded tasks
local function sync()
  if (not State.file) and #State.tasks > 0 then
    -- if file doesn't exist and there are tasks, create it
    local name = State.file_name
    local cwd = vim.fn.getcwd()
    local file = io.open(cwd .. separator .. name, "w")
    assert(file, "couldn't create " .. name .. " in current cwd: " .. cwd)

    file:write("")
    file:close()

    State.file = cwd .. separator .. name
  elseif State.file and #State.tasks == 0 then
    -- if file exists and there are no tasks, delete it
    vim.schedule_wrap(function()
      local success, err, err_name = (vim.uv or vim.loop).fs_unlink(State.file)

      if not success then
        utils.notify(tostring(err_name) .. ":" .. tostring(err), vim.log.levels.ERROR)
      end
    end)()
  end

  if State.file and vim.fn.writefile(State.tasks, State.file) ~= 0 then
    utils.notify("error writing to tasks file", vim.log.levels.ERROR)
  end
end

function State.add(str, to_front)
  if to_front then
    table.insert(State.tasks, 1, str)
  else
    table.insert(State.tasks, str)
  end

  sync()
end

function State.done()
  table.remove(State.tasks, 1)
  sync()
end

function State.set(tasks)
  State.tasks = tasks
  sync()
end

return State
