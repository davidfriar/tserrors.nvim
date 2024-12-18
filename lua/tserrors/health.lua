local function check_pretty_ts_errors_markdown_installed()
  local jsonString = vim.json.encode({
    message = "oops",
  })
  local cmd = { "pretty-ts-errors-markdown", "-i", jsonString }
  local ok, result = pcall(vim.system, cmd, { text = true })
  if not ok then
    vim.health.error([[The pretty-ts-errors-markdown application is not installed or not working correctly.
Try running 'npm install -g pretty-ts-errors-markdown'. The error reported was : ]] .. result)
  else
    vim.health.ok("The pretty-ts-errors-markdown application is installed")
  end
end

local function check_render_markdown_installed()
  local ok, result = pcall(require, "render-markdown")
  if not ok then
    vim.health.error("Missing dependency - The render-markdown.nvim plugin is not installed or not yet loaded.")
  else
    vim.health.ok("The render-markdown.nvim plugin is installed")
  end
end

return {
  check = function()
    vim.health.start("TS Errors")
    check_pretty_ts_errors_markdown_installed()
    check_render_markdown_installed()
  end,
}
