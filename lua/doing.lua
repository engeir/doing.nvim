-- A tinier task manager that helps you stay on track.
local doing = require("doing.core")

local do_cmds = {
  ---@param args_list string[]
  ---@param bang boolean
  ["add"] = function(args_list, bang)
    -- assembles the rest of the arguments into a string
    local cmd_args = ""
    for _, arg in ipairs(args_list) do
      cmd_args = cmd_args .. arg .. " "
    end

    doing.add(cmd_args, bang)
  end,

  ["status"] = function()
    vim.notify(doing.status(true), vim.log.levels.INFO, { title = "doing.nvim", })
  end,

  ["edit"] = doing.edit,
  ["done"] = doing.done,
  ["toggle"] = doing.toggle,
}

-- sets up the `:Do` command
vim.api.nvim_create_user_command("Do", function(args)
  local args_list = vim.split(args.args, "%s+", { trimempty = true, })
  local cmd = table.remove(args_list, 1)

  if vim.tbl_contains(vim.tbl_keys(do_cmds), cmd) then
    do_cmds[cmd](args_list, args.bang)
  else
    vim.notify("invalid command: " .. cmd, vim.log.levels.ERROR,
      { title = "doing.nvim", })
  end
end, {
  nargs = "?",
  bang = true,
  complete = function(_, cmd_line)
    local params = vim.split(cmd_line, "%s+", { trimempty = true, })

    if #params == 1 then
      return vim.tbl_keys(do_cmds)
    end
  end,
})

return doing
