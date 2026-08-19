local M = {}

local ts = vim.treesitter

local function get_markdown_headings(bufnr)
  bufnr = bufnr or 0
  local ok, parser = pcall(ts.get_parser, bufnr, "markdown")
  if not ok or not parser then return {} end
  local tree = parser:parse()[1]
  if not tree then return {} end
  local root = tree:root()

  local query = [[
    (atx_heading) @heading
    (setext_heading) @heading
  ]]
  local q = ts.query.parse("markdown", query)

  local headings = {}
  for id, node in q:iter_captures(root, bufnr, 0, -1) do
    if q.captures[id] == "heading" then
      local srow, _, erow, _ = node:range()
      local txt = ts.get_node_text(node, bufnr) or ""
      local level = 0
      local atx = txt:match("^%s*(#+)")
      if atx then
        level = #atx
      else
        local lines = {}
        for l in txt:gmatch("([^\\n]*)\\n?") do
          table.insert(lines, l)
        end
        local underline = lines[#lines] or ""
        if underline:match("^%s*=+%s*$") then
          level = 1
        elseif underline:match("^%s*-+%s*$") then
          level = 2
        end
      end
      table.insert(headings, {node = node, level = level, start = srow, ["end"] = erow})
    end
  end

  table.sort(headings, function(a,b) return a.start < b.start end)
  return headings
end

local function zr_inner_markdown_parent(parent_level)
  parent_level = parent_level or 2
  local bufnr = 0
  local cur_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local headings = get_markdown_headings(bufnr)
  if #headings == 0 then
    vim.notify("No markdown headings found", vim.log.levels.INFO)
    return
  end

  local parent = nil
  for i = #headings, 1, -1 do
    local h = headings[i]
    if h.start <= cur_line and h.level == parent_level then
      parent = {idx = i, start = h.start, ["end"] = h["end"]}
      break
    end
  end

  if not parent then
    vim.notify(("No enclosing H%d found above cursor"):format(parent_level), vim.log.levels.INFO)
    return
  end

  local finish = vim.api.nvim_buf_line_count(bufnr) - 1
  for j = parent.idx + 1, #headings do
    local h = headings[j]
    if h.level <= parent_level then
      finish = h.start - 1
      break
    end
  end

  local win = vim.api.nvim_get_current_win()
  local saved = vim.api.nvim_win_get_cursor(win)

  for l = parent.start + 1, finish + 1 do
    if vim.fn.foldlevel(l) >= parent_level + 1 and vim.fn.foldclosed(l) ~= -1 then
      vim.api.nvim_win_set_cursor(win, {l, 0})
      vim.cmd("normal! zO")
    end
  end

  vim.api.nvim_win_set_cursor(win, saved)
end

function M.setup(opts)
  opts = opts or {}
  local parent_level = opts.parent_level or 2
  local cmd_name = opts.cmd_name or "ZrInnerMD"
  local keymap = opts.keymap or "<leader>zr"

  vim.api.nvim_create_user_command(cmd_name, function(args)
    local lvl = tonumber(args.args) or parent_level
    zr_inner_markdown_parent(lvl)
  end, {nargs = "?"})

  vim.keymap.set('n', keymap, function() zr_inner_markdown_parent(parent_level) end, {silent = true, desc = "Open inner folds (H3+) in current H2"})
end

-- Auto-setup with defaults when the module is required.
M.setup()

return M
