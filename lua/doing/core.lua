local view = require("doing.view")
local edit = require("doing.edit")
local state = require("doing.state")

local Core = {}

---setup doing.nvim
---@param opts DoingOptions
function Core.setup(opts)
  state.options = vim.tbl_deep_extend("force", state.default_opts, opts or {})
  state.tasks = state.init(state.options.store)

  Core.setup_winbar()

  return Core
end

---add a task to the list
function Core.add(task, to_front)
  state.tasks:sync(true)
  if task == nil then
    vim.ui.input({ prompt = 'Enter the new task: ' },
      function(input)
        state.tasks:add(input, to_front)
        Core.redraw_winbar_if_needed()
        Core.exec_task_modified_autocmd()
      end)
  else
    state.tasks:add(task, to_front)
    Core.redraw_winbar_if_needed()
    Core.exec_task_modified_autocmd()
  end
end

---edit the tasks in a floating window
function Core.edit()
  edit.open_edit(state.tasks:get(), function(new_todos)
    state.tasks:set(new_todos)
    Core.exec_task_modified_autocmd()
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

    Core.exec_task_modified_autocmd()
  else
    Core.show_message("There was nothing left to do ")
  end
end

---toggle the visibility of the plugin
function Core.toggle_display()
  state.view_enabled = not state.view_enabled
  Core.redraw_winbar_if_needed()
end

---configure displaying current to do item in winbar
function Core.setup_winbar()
  if state.options.winbar.enabled then
    _G.DoingStatusline = view.status

    vim.g.winbar = view.stl
    vim.api.nvim_set_option_value("winbar", view.stl, {})

    state.auGroupID = vim.api.nvim_create_augroup("doing_nvim", { clear = true })

    -- winbar should not be displayed in windows the cursor is not in
    vim.api.nvim_create_autocmd({ "WinEnter", "WinLeave", "BufEnter", "BufLeave" }, {
      group = state.auGroupID,
      callback = function()
        if state.view_enabled then
          Core.redraw_winbar_if_needed()
        end
      end,
    })
  end
end

---redraw winbar depending on if there are tasks. Redraw if there are pending tasks, other wise set to ""
function Core.redraw_winbar_if_needed()
  if state.options.winbar.enabled then
    if state.view_enabled
        and (state.tasks:count() > 0 or state.message)
        and Core.should_display()
    then
      vim.wo.winbar = view.stl
    else
      vim.wo.winbar = ""

      vim.cmd([[ set winbar= ]])
      vim.cmd([[ redrawstatus ]])
    end
  end
end

---checks whether the current window/buffer can display a winbar
function Core.should_display()
  if vim.api.nvim_buf_get_name(0) == "" or
      vim.fn.win_gettype() == "preview" then
    return false
  end

  local ignore = state.options.ignored_buffers

  if type(ignore) == "function" then
    ignore = ignore()
  end

  local home_path_abs = tostring(os.getenv("HOME"))

  for _, exclude in ipairs(ignore) do
    if string.find(vim.bo.filetype, exclude)                        -- match filetype
        or exclude == vim.fn.expand("%")                            -- match filename
        or exclude:gsub("~", home_path_abs) == vim.fn.expand("%:p") -- match filepath
    then
      return false
    end
  end

  return vim.fn.win_gettype() == ""        -- is a normal window
      and not (vim.bo.buftype == "prompt") -- and not a prompt buffer
end

---show a message for the duration of `options.message_timeout`
function Core.show_message(str)
  state.message = str

  vim.defer_fn(function()
    state.message = nil
    Core.redraw_winbar_if_needed()
  end, state.default_opts.message_timeout)

  Core.redraw_winbar_if_needed()
end

---execute the auto command when a task is modified
function Core.exec_task_modified_autocmd()
  vim.api.nvim_exec_autocmds("User", {
    pattern = "TaskModified",
    group = state.auGroupID,
  })
end

return Core
