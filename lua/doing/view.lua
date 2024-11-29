local state = require("doing.state")

local View = {}

---Create a winbar string for the current task
function View.status()
  if state.view_enabled and
      require("doing.core").should_display()
  then
    local tasks_left = ""

    -- using pcall so that it won't spam error messages
    local ok, current_string = pcall(function()
      if state.message then
        return state.message
      end

      local count = state.tasks:count()

      if count == 0 then
        return ""
      end

      local res = state.options.doing_prefix .. state.tasks:current()

      -- append task count number if there is more than 1 task
      if count > 1 then
        tasks_left = '+' .. (count - 1) .. " more"
      end

      return res
    end)

    if not ok then
      return "ERR: " .. current_string
    end

    if not tasks_left then
      return current_string
    end

    return current_string .. '  ' .. tasks_left
  else
    return ""
  end
end

View.stl = "%!v:lua.DoingStatusline('active')"

return View
