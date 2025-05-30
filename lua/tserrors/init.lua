local M = {}

M.window = nil
M.buffer = nil

---@type tserrors.Options
M.config = require("tserrors.config").options

local function split_into_lines(text)
  local result = {}
  local index = 1
  for line in string.gmatch(text, "[^\r\n]+") do
    result[index] = line
    index = index + 1
  end
  return result
end

local function configure_render_markdown()
  local state = require("render-markdown.state")
  state.file_types[#state.file_types + 1] = M.config.file_type
  state.config.overrides.filetype[M.config.file_type] = M.config.markdown_overrides
  state.validate()
end

local function remove_links(lines)
  local first_line = lines[1]
  if first_line then
    local pattern = "%b[].-%b()"
    lines[1] = first_line:gsub(pattern, "")
  end
  return lines
end

local function calculate_dimensions(text_lines, max_width, max_height)
  local height = 0
  local width = 0
  local max_inner_width = max_width - M.config.padding * 2
  for _, s in pairs(text_lines) do
    local cols = vim.fn.strdisplaywidth(s)
    if cols > width then
      width = cols
    end
    height = height + math.ceil(cols / max_inner_width)
  end
  return math.min(width, max_width), math.min(height, max_height)
end

function M.get_diagnostics_for_cursor()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lnum = line - 1
  local diagnostics = vim.diagnostic.get(0)
  return vim.tbl_filter(function(d)
    return ((d.lnum == lnum and d.col <= col) or d.lnum < lnum)
      and ((d.end_lnum == lnum and d.end_col >= col) or d.end_lnum > lnum)
  end, diagnostics)
end

function M.convert_to_mark_down(diagnostic)
  local jsonString = M.diagnostic_to_json(diagnostic)
  local cmd = { "pretty-ts-errors-markdown", "-i", jsonString }
  local ok, result = pcall(vim.system, cmd, { text = true })
  if not ok then
    vim.notify("Call to pretty-ts-errors-markdown failed.", vim.log.levels.ERROR)
    return
  end
  return result:wait()["stdout"]
end

function M.diagnostic_to_json(diagnostic)
  local lspDiagnostics = {
    range = {
      start = {
        line = diagnostic.lnum,
        character = diagnostic.col,
      },
      ["end"] = {
        line = diagnostic.end_lnum,
        character = diagnostic.end_col,
      },
    },
    message = diagnostic.message,
    code = diagnostic.code,
    severity = diagnostic.severity,
    source = diagnostic.source,
  }
  return vim.json.encode(lspDiagnostics)
end

--- Show a nicely formatted version of the diagnostic for the current cursor position in a popup window
function M.show_diagnostic_for_cursor()
  local diagnostics = M.get_diagnostics_for_cursor()
  if diagnostics and #diagnostics > 0 then
    local markdown = M.convert_to_mark_down(diagnostics[1])
    M.show_diagnostic(markdown)
  end
end

--- Close the popup window if it is open.
function M.close()
  if M.is_open() then
    vim.api.nvim_win_close(M.window, true)
  end
  if vim.api.nvim_buf_is_valid(M.buffer) then
    vim.api.nvim_buf_delete(M.buffer, { force = true })
  end
end

--- Close the popup window if it is already open, otherwise call show_diagnostic_for_cursor in order to show the diagnostic for the current cursor position.
function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.show_diagnostic_for_cursor()
  end
end

function M.is_open()
  return M.window and vim.api.nvim_win_is_valid(M.window)
end

local function scroll(down)
  if M.is_open() then
    local command = [[exe "normal \<c-u>"]]
    if down then
      command = [[exe "normal \<c-d>"]]
    end
    vim.api.nvim_win_call(M.window, function()
      vim.cmd(command)
    end)
  end
end

--- Scroll the popup window down by half a screen
function M.scroll_down()
  scroll(true)
end

--- Scroll the popup window up by half a screen
function M.scroll_up()
  scroll(false)
end

--- Move the focus into the popup window. Useful if you need for example
--- to copy the contents of the window, which with the default configuration
--- is not a focusable window.
function M.focus()
  if M.is_open() then
    vim.api.nvim_set_current_win(M.window)
  end
end

local function create_autoclose_commands()
  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufDelete" }, {
    buffer = vim.api.nvim_get_current_buf(),
    callback = function(params)
      M.close()
      vim.api.nvim_del_autocmd(params.id)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    callback = function(params)
      if params.buf ~= M.buffer then
        M.close()
        vim.api.nvim_del_autocmd(params.id)
      end
    end,
  })
end

function M.open_window(buffer, width, height)
  local opts = vim.tbl_extend("error", M.config.win_open_opts, { width = width, height = height })
  M.window = vim.api.nvim_open_win(buffer, false, opts)
  for k, v in pairs(M.config.window_options) do
    vim.wo[M.window][k] = v
  end
  vim.wo[M.window].statuscolumn = string.rep(" ", M.config.padding)
  create_autoclose_commands()
end

function M.create_buffer(text_lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = M.config.file_type
  vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text_lines)
  for k, v in pairs(M.config.buffer_options) do
    vim.bo[buf][k] = v
  end
  M.buffer = buf
end

function M.show_diagnostic(text)
  local text_lines = remove_links(split_into_lines(text))
  local width, height = calculate_dimensions(text_lines, M.config.max_width, M.config.max_height)
  M.create_buffer(text_lines)
  if not M.is_open() then
    M.open_window(M.buffer, width, height)
  else
    vim.api.nvim_win_set_buf(M.window, M.buffer)
  end
end

--- Configure the plugin with your custom options. Set MUST be called for the plugin to work.
--- Either call it explicitly, or, if you are using Lazy.nvim, provide a value for 'opts' in
--- your plugin configuration and Lazy will call it for you. Note that '{}' is a valid value
--- for setup, if you don't want to cusonise anything.
--- @param options tserrors.UserOptions
function M.setup(options)
  local config = require("tserrors.config")
  config.setup(options)
  M.config = config.options
  configure_render_markdown()
  vim.treesitter.language.register("markdown", M.config.file_type)
  require("tserrors.command").create_command()
end

return M
