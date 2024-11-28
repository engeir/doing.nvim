local Api   = {}

local view  = require("doing.view")
local state = require("doing.state")
local core  = require('doing.core')
local utils = require("doing.utils")

---Create a status string for the current task
---@return string|table
function Api.status()
  return view.status()
end

---add a task to the list
---@param str string task to add
---@param to_front boolean whether to add task to front of list
function Api.add(str, to_front)
  state.tasks:add(str, to_front)
  if state.options.winbar.enabled then
    core.redraw_winbar()
  end
  utils.exec_task_modified_autocmd()
end

---edit the tasks in a floating window
function Api.edit()
  core.edit()
end

---finish the first task
function Api.done()
  core.done()
end

-- toggles display
function Api.toggle()
  core.toggle_display()
end

return Api
