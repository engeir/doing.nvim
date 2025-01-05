-- A tinier task manager that helps you stay on track.
local state = require("doing.state")
local utils = require("doing.utils")
local edit  = require("doing.edit")

local Doing = {}

---setup doing.nvim
---@param opts? DoingOptions
function Doing.setup(opts)
  state.options = vim.tbl_deep_extend("force", state.default_opts, opts or {})
  state.tasks = state.init(state.options.store)

  -- doesn't touch the winbar if disabled so other plugins can manage
  -- it without interference
  if state.options.winbar.enabled then
    state.auGroupID = vim.api.nvim_create_augroup("doing_nvim", { clear = true, })

    vim.api.nvim_create_autocmd({ "BufEnter", }, {
      group = state.auGroupID,
      callback = function()
        -- gives time to process filetype
        vim.defer_fn(function()
          utils.update_winbar()
        end, 100)
      end,
    })
  end
end

---add a task to the list
---@param task? string task to add
---@param to_front? boolean whether to add task to front of list
function Doing.add(task, to_front)
  if not state.tasks then
    Doing.setup()
  end

  if task then
    if task:sub(1,1) == '"' and task:sub(-1,-1) == '"' then
      task = task:sub(2, -2)
    end

    state.tasks:add(task, to_front)
    utils.task_modified()
  else
    vim.ui.input({ prompt = "Enter the new task: ", }, function(input)
      state.tasks:add(input, to_front)
      utils.task_modified()
    end)
  end
end

---edit the tasks in a floating window
function Doing.edit()
  if not state.tasks then
    Doing.setup()
  end

  edit.open_edit(state.tasks:get(), function(new_todos)
    state.tasks:set(new_todos)
    utils.task_modified()
  end)
end

---finish the current task
function Doing.done()
  if not state.tasks then
    Doing.setup()
  end

  if state.tasks:count() > 0 then
    state.tasks:pop()

    if state.tasks:count() == 0 then
      utils.show_message("All tasks done ")
    elseif not state.options.show_remaining then
      utils.show_message(state.tasks:count() .. " tasks left.")
    else
      utils.task_modified()
    end
  else
    utils.show_message("Not doing any task")
  end
end

-- returns current plugin task/message
-- @param force boolean displays the message even if the plugin display is turned off
function Doing.status(force)
  if not state.tasks then
    Doing.setup()
  end

  if (state.view_enabled or force) and utils.should_display() then
    if state.message then
      return state.message
    elseif state.tasks:count() > 0 then
      local tasks_left = ""
      local count = state.tasks:count()

      -- append task count number if there is more than 1 task
      if state.options.show_remaining and count > 1 then
        tasks_left = "  +" .. (state.tasks:count() - 1) .. " more"
      end

      return state.options.doing_prefix .. state.tasks:current() .. tasks_left
    elseif force then
      return "Not doing any tasks"
    end
  end
  return ""
end

---toggle the visibility of the plugin
function Doing.toggle()
  state.view_enabled = not state.view_enabled
  utils.task_modified()
end

return Doing
