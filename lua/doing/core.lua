local edit = require("doing.edit")
local state = require("doing.state")

local Core = {}

---setup doing.nvim
---@param opts DoingOptions
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
        if state.view_enabled then
          -- gives time to process filetype
          vim.defer_fn(Core.update_winbar, 100)
        end
      end,
    })
  end
end

---add a task to the list
function Core.add(task, to_front)
  state.tasks:sync(true)
  if task == nil then
    vim.ui.input({ prompt = "Enter the new task: ", }, function(input)
      state.tasks:add(input, to_front)
      Core.task_modified()
    end)
  else
    state.tasks:add(task, to_front)
    Core.task_modified()
  end
end

---edit the tasks in a floating window
function Core.edit()
  edit.open_edit(state.tasks:get(), function(new_todos)
    state.tasks:set(new_todos)
    Core.task_modified()
  end)
end

---finish the current task
function Core.done()
  if state.tasks:count() > 0 then
    state.tasks:pop()

    if state.tasks:count() == 0 then
      Core.show_message("All tasks done ")
    else
      Core.show_message(state.tasks:count() .. " left.")
    end

    Core.task_modified()
  else
    Core.show_message("There was nothing left to do ")
  end
end

---show a message for the duration of `options.message_timeout`
function Core.show_message(str)
  state.message = str
  Core.update_winbar()

  vim.defer_fn(function()
    state.message = nil
    Core.update_winbar()
  end, state.default_opts.message_timeout)
end

-- TODO: lualine calls this function way too often
function Core.status()
  if state.view_enabled and Core.should_display() then
    if state.message then
      return state.message
    elseif state.tasks:count() > 0 then
      local tasks_left = ""
      local count = state.tasks:count()

      -- append task count number if there is more than 1 task
      if count > 1 then
        tasks_left = "  +" .. (state.tasks:count() - 1) .. " more"
      end

      return state.options.doing_prefix .. state.tasks:current() .. tasks_left
    end
  end
  return ""
end

---redraw winbar depending on if there are tasks
function Core.update_winbar()
  if state.options.winbar.enabled -- winbar enabled
     and Core.should_display()    -- is a valid buffer to display
  then
    vim.api.nvim_set_option_value("winbar", Core.status(), { scope = "local", })
  end
end

---checks whether the current window/buffer can display a winbar
function Core.should_display()
  if (vim.fn.win_gettype() ~= "preview"
       or vim.bo.buftype ~= "popup"
       or vim.bo.buftype ~= "prompt")
     and vim.fn.win_gettype() == "" -- normal window
  then
    local ignore = state.options.ignored_buffers

    if type(ignore) == "function" then
      ignore = ignore()
    end

    local home_path_abs = tostring(os.getenv("HOME"))

    for _, exclude in ipairs(ignore) do
      if
         vim.bo.filetype:find(exclude)                               -- match filetype
         or exclude == vim.fn.expand("%")                            -- match filename
         or exclude:gsub("~", home_path_abs) == vim.fn.expand("%:p") -- match filepath
      then
        return false
      end
    end
    return true
  else
    return false
  end
end

---toggle the visibility of the plugin
function Core.toggle_display()
  state.view_enabled = not state.view_enabled
  Core.update_winbar()
end

---execute the auto command when a task is modified
function Core.task_modified()
  Core.update_winbar()
  vim.api.nvim_exec_autocmds("User", {
    pattern = "TaskModified",
    group = state.auGroupID,
  })
end

return Core
