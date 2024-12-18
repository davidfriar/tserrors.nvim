local main = require("tserrors")

local sub_cmds = {
  toggle = main.toggle,
  scroll_down = main.scroll_down,
  scroll_up = main.scroll_up,
  focus = main.focus,
  show_diagnostic = main.show_diagnostic_for_cursor,
  close = main.close,
}

local sub_cmds_keys = {}
for k, _ in pairs(sub_cmds) do
  table.insert(sub_cmds_keys, k)
end

local function main_cmd(opts)
  local sub_cmd = sub_cmds[opts.args]
  if sub_cmd == nil then
    vim.print("Base: invalid subcommand")
  else
    sub_cmd()
  end
end

return {
  create_command = function()
    vim.api.nvim_create_user_command("TSErrors", main_cmd, {
      nargs = "?",
      desc = "Show pretty Typescript errors",
      complete = function(arg_lead, _, _)
        return vim
          .iter(sub_cmds_keys)
          :filter(function(sub_cmd)
            return sub_cmd:find(arg_lead) ~= nil
          end)
          :totable()
      end,
    })
  end,
}
