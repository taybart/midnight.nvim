-- Checks queries/midnight/aerial.scm against aerial.nvim: the symbols for
-- fixture.mn must match expected.txt. Run w/ `make test-aerial`, or:
--   nvim --headless -u NONE -l test/aerial/run.lua <aerial.nvim> <midnight.so> [--update]
local aerial_path, parser_path = arg[1], arg[2]
local update = arg[3] == '--update'
local dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
local root = vim.fn.fnamemodify(dir, ':h:h')

vim.opt.rtp:prepend(aerial_path)
vim.opt.rtp:prepend(root)
vim.filetype.add({ extension = { mn = 'midnight' } })
vim.treesitter.language.add('midnight', { path = parser_path })

require('aerial').setup({ backends = { 'treesitter' }, filter_kind = false })
require('aerial').sync_load() -- setup is deferred until first use

vim.cmd.edit(dir .. '/fixture.mn')
vim.bo.filetype = 'midnight' -- no filetype detection w/ -u NONE
local backend = require('aerial.backends.treesitter')
local supported, err = backend.is_supported(0)
if not supported then
  io.stderr:write('aerial: ' .. tostring(err) .. '\n')
  os.exit(1)
end
backend.fetch_symbols_sync(0)

local lines = {}
local function walk(items, depth)
  for _, item in ipairs(items or {}) do
    local scope = item.scope and (' (' .. item.scope .. ')') or ''
    table.insert(lines, ('%s%s %s%s :%d'):format(('  '):rep(depth), item.kind, item.name, scope, item.lnum))
    walk(item.children, depth + 1)
  end
end
walk(require('aerial.data').get_or_create(0).items, 0)

local expected_path = dir .. '/expected.txt'
if update then
  vim.fn.writefile(lines, expected_path)
  print('updated ' .. expected_path)
  os.exit(0)
end

local expected = vim.fn.readfile(expected_path)
if vim.deep_equal(lines, expected) then
  print('ok: ' .. #lines .. ' symbols')
  os.exit(0)
end
io.stderr:write('symbols differ from expected.txt\n--- got:\n' .. table.concat(lines, '\n') .. '\n')
os.exit(1)
