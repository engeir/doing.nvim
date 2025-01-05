# doing.nvim

<a href="https://www.buymeacoffee.com/hashino" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 24px !important;width: 104px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>


A tiny task manager within neovim that helps you stay on track by keeping a stack
of tasks and always showing the first task and how many more you have.

It works by storing the tasks in a plain text file

this plugin was originally a fork of [nocksock/do.nvim](https://github.com/nocksock/do.nvim)

![doing](https://raw.githubusercontent.com/Hashino/doing.nvim/main/demo.gif)

## Commands

### Adding Tasks

- `:Do add {task}` 
- `:Do {task}`
- `:Do "{task}"`

will all add `{task}` to the end of the tasklist

- `:Do! add {task}` 
- `:Do! {task}`
- `:Do! "{task}"`

will all add `{task}` to the start of the tasklist

### Other Commands

- `:Do status` shows notification with current task/message (even if toggled off)
- `:Do done` remove the first task from the list
- `:Do edit` edit the tasklist in a floating window
- `:Do toggle` toggle the display (winbar and status)

## Installation

lazy.nvim:
```lua
-- minimal installation
{
  "Hashino/doing.nvim",
  cmd = "Do", -- lazy loads on `:Do` command
}
```

## Configuration

### Default Configs

[see the source code for default configs](https://github.com/Hashino/doing.nvim/blob/e4639e848b1503c14a591e3bfc6862560eeccefb/lua/doing/state.lua#L18-L45)

### Example Config

```lua
{
  "Hashino/doing.nvim",
  config = function()
    -- default options
    require("doing").setup {
      message_timeout = 2000,
      doing_prefix = "Doing: ",

      -- doesn"t display on buffers that match filetype/filename/filepath to
      -- entries. can be either a string array or a function that returns a
      -- string array. filepath can be relative to cwd or absolute
      ignored_buffers = { "NvimTree" },

      -- if should append "+n more" to the status when there's tasks remaining
      show_remaining = true,

      -- window configs of the floating tasks editor
      -- see :h nvim_open_win() for available options
      edit_win_config = {
        width = 50,
        height = 15,
        border = "rounded",
      }

      -- if plugin should manage the winbar
      winbar = { enabled = true, },

      store = {
        -- name of tasks file
        file_name = ".tasks",
      },
    }
    -- example on how to change the winbar highlight
    vim.api.nvim_set_hl(0, "WinBar", { link = "Search" })

    local doing = require("doing")

    vim.keymap.set("n", "<leader>da", doing.add, { desc = "[D]oing: [A]dd" })
    vim.keymap.set("n", "<leader>de", doing.edit, { desc = "[D]oing: [E]dit" })
    vim.keymap.set("n", "<leader>dn", doing.done, { desc = "[D]oing: Do[n]e" })
    vim.keymap.set("n", "<leader>dt", doing.toggle, { desc = "[D]oing: [T]oggle" })

    vim.keymap.set("n", "<leader>ds", function()
      vim.notify(doing.status(true), vim.log.levels.INFO,
        { title = "Doing:", icon = "", })
    end, { desc = "[D]oing: [S]tatus", })
  end,
}
```

### Integration

In case you'd rather display the tasks with another plugin instead of the
default winbar implementation, you can use the exposed views to do so.

For example with lualine:

```lua
require("lualine").setup {
  winbar = {
    lualine_a = { require("doing").status },
  },
}
```

with heirline:
```lua
{
  provider = function()
    return " " .. require("doing").status() .. " "
  end,
  update = { "BufEnter", "User", pattern = "TaskModified", },
},
```

### Events

This plugin exposes a custom event, for when a task is added, edited or
completed. You can use it like so:

```lua
vim.api.nvim_create_autocmd({ "User" }, {
   group = require("doing.state").auGroupID,
   pattern = "TaskModified",
   desc = "This is called when a task is added, edited or completed",
   callback = function()
      vim.notify("A task has been modified")
   end,
})
```

### Recipes

If your winbar is already in use and your status bar is full, you can use doing
with just notifications:

```lua
{
  "Hashino/doing.nvim",
  lazy = true,
  init = function()
    local doing = require("doing")

    -- example keymaps
    vim.keymap.set("n", "<leader>da", doing.add, { desc = "[D]oing: [A]dd", })
    vim.keymap.set("n", "<leader>de", doing.edit, { desc = "[D]oing: [E]dit", })
    vim.keymap.set("n", "<leader>dn", doing.done, { desc = "[D]oing: Do[n]e", })

    vim.keymap.set("n", "<leader>ds", function()
      vim.notify(doing.status(true), vim.log.levels.INFO,
        { title = "Doing:", icon = "", })
    end, { desc = "[D]oing: [S]tatus", })

    vim.api.nvim_create_autocmd({ "User", }, {
      group = require("doing.state").auGroupID,
      pattern = "TaskModified",
      desc = "This is called when a task is added, edited or completed",
      callback = function()
        vim.defer_fn(function()
          local status = doing.status()
          if status ~= "" then
            vim.notify(status, vim.log.levels.INFO,
              { title = "Doing:", icon = "", })
          end
        end, 0)
      end,
    })
  end,
}
```
