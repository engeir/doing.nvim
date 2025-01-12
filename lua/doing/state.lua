local config = require("doing.config")
local utils = require("doing.utils")
local dir_separator = utils.get_path_separator()

local State = {}

State.file = nil
State.message = nil
State.file_name = nil
State.view_enabled = true
State.auGroupID = nil

State.file_name = config.options.store.file_name

vim.api.nvim_create_autocmd("DirChanged", {
  group = State.auGroupID,
  callback = function()
    State.tasks = State.import_file() or {}
  end,
})

---creates a file based on configs
---@return string path to the created file
function State.create_file()
  local name = State.file_name
  local cwd = vim.fn.getcwd()
  local file = io.open(cwd .. dir_separator .. name, "w")
  assert(file, "couldn't create " .. name .. " in current cwd: " .. cwd)

  file:write("")
  file:close()

  return cwd .. dir_separator .. name
end

---finds tasks file in cwd
---@return string[]|nil tasks tasklist or nil if file not found
function State.import_file()
  local file = vim.fn.findfile(vim.fn.getcwd() .. dir_separator .. State.file_name, ".;")

  if file == "" then
    State.file = nil
  else
    local is_readable = vim.fn.filereadable(file) == 1
    assert(is_readable, string.format("file not %s readable", file))

    State.file = file
  end

  return State.file and vim.fn.readfile(State.file) or nil
end

local function delete_file(file_path)
  vim.schedule_wrap(function()
    local success, err, err_name = (vim.uv or vim.loop).fs_unlink(file_path)

    if not success then
      utils.notify(tostring(err_name) .. ":" .. tostring(err), vim.log.levels.ERROR)
    end
  end)()
end

---syncs file tasks with loaded tasks
function State.sync()
  if (not State.file) and #State.tasks > 0 then
    State.file = State.create_file()
  elseif State.file and #State.tasks == 0 then
    delete_file(State.file)
  end

  if State.file and vim.fn.filewritable(State.file) and State.tasks ~= {} then
    local res = vim.fn.writefile(State.tasks, State.file)
    if res ~= 0 then
      utils.notify("error writing to tasks file", vim.log.levels.ERROR)
    end
  end
end

function State.set(tasks)
  State.tasks = tasks
  State.sync()
end

function State.add(str, to_front)
  if to_front then
    table.insert(State.tasks, 1, str)
  else
    table.insert(State.tasks, str)
  end

  State.sync()
end

function State.done()
  table.remove(State.tasks, 1)
  State.sync()
end

-- for lazy loading
if not State.tasks then
  State.tasks = State.import_file() or {}
end

return State
