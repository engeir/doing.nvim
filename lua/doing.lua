-- A tinier task manager that helps you stay on track.
local doing = require("doing.core")

local do_cmds = {
  ["add"] = doing.add,
  ["edit"] = doing.edit,
  ["done"] = doing.done,
  ["toggle"] = doing.toggle,

  ["status"] = function()
    vim.notify(doing.status(true), vim.log.levels.INFO, { title = "doing.nvim", })
  end,
}

-- sets up the `:Do` command
vim.api.nvim_create_user_command("Do", function(args)
  -- split the command and the arguments by the first space
  local cmd = args.args:sub(1, args.args:find(" ") or (#args.args + 1) - 1)
  local cmd_args = args.args:sub(#cmd + 2) or ""

  if vim.tbl_contains(vim.tbl_keys(do_cmds), cmd) then
    do_cmds[cmd](cmd_args, args.bang)
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
