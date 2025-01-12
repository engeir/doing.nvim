local config = require("doing.config")
local state  = require("doing.state")
local utils  = require("doing.utils")
local edit   = require("doing.edit")

local Doing  = {}

--- setup doing.nvim
---@param opts? DoingOptions
function Doing.setup(opts)
  config.options = vim.tbl_deep_extend("force", config.default_opts, opts or {})

  -- doesn't touch the winbar if disabled so other plugins can manage
  -- it without interference
  if config.options.winbar.enabled then
    state.auGroupID = vim.api.nvim_create_augroup("doing_nvim", { clear = true, })

    vim.api.nvim_create_autocmd({ "BufEnter", }, {
      group = state.auGroupID,
      callback = function()
        -- HACK: gives time to process filetype
        vim.defer_fn(function()
          utils.update_winbar()
        end, 100)
      end,
    })
  end
end

--- add a task to the list
---@param task? string task to add
---@param to_front? boolean whether to add task to front of list
function Doing.add(task, to_front)
  if task ~= nil and task ~= "" then
    -- remove quotes if present
    if task:sub(1, 1) == '"' and task:sub(-1, -1) == '"' then
      task = task:sub(2, -2)
    end

    state.add(task, to_front)
    utils.task_modified()
  else
    vim.ui.input({ prompt = "Enter the new task: ", }, function(input)
      state.add(input, to_front)
      utils.task_modified()
    end)
  end
end

---edit the tasks in a floating window
function Doing.edit()
  edit.open_edit(state)
end

---finish the current task
function Doing.done()
  if #state.tasks > 0 then
    state.done()

    if #state.tasks == 0 then
      utils.show_message("All tasks done ")
    elseif not config.options.show_remaining then
      utils.show_message(#state.tasks .. " tasks left.")
    else
      utils.task_modified()
    end
  else
    utils.show_message("Not doing any task")
  end
end

---@param force? boolean return status even if the plugin is toggled off
---@return string current current plugin task or message
function Doing.status(force)
  if (state.view_enabled or force) and utils.should_display() then
    local count = #state.tasks or 0
    if state.message then
      return state.message
    elseif count > 0 then
      local tasks_left = ""

      -- append task count number if there is more than 1 task
      if config.options.show_remaining and count > 1 then
        tasks_left = "  +" .. (count - 1) .. " more"
      end

      return config.options.doing_prefix .. state.tasks[1] .. tasks_left
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

---@return integer number of tasks left
function Doing.tasks_left()
  return #state.tasks or 0
end

return Doing
