local M = {}

local function slack_reformat(lines)
  local out = {}
  for _, line in ipairs(lines) do
    -- Markdown bullets -> Slack bullets (preserve indentation)
    line = line:gsub("^(%s*)[%-%*%+]%s+", "%1• ")

    -- Task lists -> checkbox glyphs
    line = line:gsub("^(%s*)•%s+%[ %]%s+", "%1• ☐ ")
    line = line:gsub("^(%s*)•%s+%[[xX]%]%s+", "%1• ☑ ")

    table.insert(out, line)
  end
  return out
end

function M.copy(opts)
  local bufnr = 0
  opts = opts or {}

  local lines
  if opts.range == 1 then
    lines = vim.api.nvim_buf_get_lines(bufnr, opts.line1 - 1, opts.line2, false)
  else
    -- No range: whole buffer
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end

  local text = table.concat(slack_reformat(lines), "\n")
  vim.fn.setreg("+", text)
  vim.fn.setreg("*", text)

  vim.notify("Copied Slack-formatted text to clipboard", vim.log.levels.INFO)
end

function M.reformat(opts)
  local bufnr = 0
  opts = opts or {}

  local start_line, end_line
  if opts.range == 1 then
    start_line = opts.line1 - 1
    end_line = opts.line2
  else
    start_line = 0
    end_line = vim.api.nvim_buf_line_count(bufnr)
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, slack_reformat(lines))

  vim.notify("Reformatted text for Slack", vim.log.levels.INFO)
end

return M
