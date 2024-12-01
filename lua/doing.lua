-- A tinier task manager that helps you stay on track.
local create = vim.api.nvim_create_user_command
local core = require("doing.core")

create("Do", function(args)
  core.add(unpack(args.fargs), args.bang)
end, { nargs = "?", bang = true, })

create("Done", core.done, {})

create("DoToggle", core.toggle_display, {})
create("DoEdit", core.edit, {})

return core
