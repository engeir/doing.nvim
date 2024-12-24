local edit = require("doing.edit")
local state = require("doing.state")
local utils = require("doing.utils")

local Core = {}

---setup doing.nvim
---@param opts? DoingOptions
function Core.setup(opts)
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
function Core.add(task, to_front)
  if task ~= nil and task ~= "" then
    state.tasks:sync()
    if task == nil then
      vim.ui.input({ prompt = "Enter the new task: ", }, function(input)
        state.tasks:add(input, to_front)
        utils.task_modified()
      end)
    else
      state.tasks:add(task, to_front)
      utils.task_modified()
    end
  else
    vim.notify("No task provided", vim.log.levels.ERROR, { title = "doing.nvim", })
  end
end

---edit the tasks in a floating window
function Core.edit()
  edit.open_edit(state.tasks:get(), function(new_todos)
    state.tasks:set(new_todos)
    utils.task_modified()
  end)
end

---finish the current task
function Core.done()
  if state.tasks:count() > 0 then
    state.tasks:pop()

    if state.tasks:count() == 0 then
      utils.show_message("All tasks done ")
    else
      utils.show_message(state.tasks:count() .. " left.")
    end

    utils.task_modified()
  else
    utils.show_message("There was nothing left to do ")
  end
end

-- returns current plugin task/message
-- @param force boolean displays the message even if the plugin display is turned off
function Core.status(force)
  if not state.tasks then
    Core.setup()
  end

  if (state.view_enabled or force) and utils.should_display() then
    if state.message then
      return state.message
    elseif state.tasks:count() > 0 then
      local tasks_left = ""
      local count = state.tasks:count()

      if state.options.show_remaining then
        -- append task count number if there is more than 1 task
        if count > 1 then
          tasks_left = "  +" .. (state.tasks:count() - 1) .. " more"
        end
      end

      return state.options.doing_prefix .. state.tasks:current() .. tasks_left
    end
  end
  if force then
    return "All tasks done"
  end
  return ""
end

---toggle the visibility of the plugin
function Core.toggle()
  state.view_enabled = not state.view_enabled
  utils.task_modified()
end

return Core
