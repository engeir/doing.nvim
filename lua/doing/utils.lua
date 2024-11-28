local Utils = {}

local state = require('doing.state')

--- execute the auto command when a task is modified
function Utils.exec_task_modified_autocmd()
  vim.api.nvim_exec_autocmds("User", {
    pattern = "TaskModified",
    group = state.auGroupID,
  })
end

---Check whether the current window/buffer can display a winbar
function Utils.should_display_task()
  if vim.api.nvim_buf_get_name(0) == "" or
      vim.fn.win_gettype() == "preview" then
    return false
  end

  for _, exclude in ipairs(state.options.winbar.ignored_buffers) do
    if string.find(vim.bo.filetype, exclude) then
      return false
    end
  end

  return vim.fn.win_gettype() == ""
      and vim.bo.buftype ~= "prompt"
end

return Utils
