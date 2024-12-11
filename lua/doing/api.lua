local core = require("doing.core")

local Api = {}

---returns the current task/message
---@return string
function Api.status()
  return core.status()
end

---add a task to the list
---@param task? string task to add
---@param to_front? boolean whether to add task to front of list
function Api.add(task, to_front)
  core.add(task or nil, to_front or false)
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
