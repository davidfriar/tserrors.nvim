local M = {}

---@type  tserrors.Options
M.defaults = {
  file_type = "tserror",
  markdown_overrides = {
    code = {
      style = "normal",
      highlight = "RenderMarkDownErrorsCode",
      left_pad = 1,
      right_pad = 1,
    },
  },
  win_open_opts = {
    focusable = false,
    relative = "cursor",
    style = "minimal",
    row = 1,
    col = 0,
    border = "rounded",
  },
  window_options = {
    wrap = true,
    linebreak = true,
  },
  buffer_options = {
    readonly = true,
    modifiable = false,
  },
  max_width = 160,
  max_height = 50,
  padding = 1,
}

---@type tserrors.Options
M.options = M.defaults

---Extend the defaults options table with the user options
---@param opts tserrors.UserOptions: plugin options
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.options, opts or {})
end

return M
