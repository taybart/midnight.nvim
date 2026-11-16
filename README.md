# midnight.nvim

Neovim support for [Midnight](https://github.com/taybart/midnight) (including
`match`, `if` / `match` expressions, and markup):

- `midnight` filetype and `gf` on `require('src/layout')`
- `gc` comments markup children w/ `{--[[ ]]}` and code w/ `--` (in .rest
  files' `<<MIDNIGHT` heredocs too)
- tree-sitter highlighting w/
  [tree-sitter-midnight](https://github.com/taybart/tree-sitter-midnight) (css/js
  injected in `<style>` / `<script>`)
- formatting w/ `midnight fmt` ([conform.nvim](https://github.com/stevearc/conform.nvim))
- diagnostics w/ `midnight lint` ([nvim-lint](https://github.com/mfussenegger/nvim-lint)),
  ex. `and-or`: `a && b || c` where `b` can be nil (use `if a { b } else { c }`)
- [rest](https://github.com/taybart/rest): lints `<<MIDNIGHT` heredocs in .rest
  files, and knows rest's globals in projects w/ a .rest file
- symbols for [aerial.nvim](https://github.com/stevearc/aerial.nvim) (see
  [aerial](#aerial))
- `:MidnightCompile` shows the lua a buffer compiles to, updated as you edit
- a file icon (󰖔) w/ [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons),
  so pickers (ex. snacks), statuslines, and file trees show it

Needs nvim 0.11+ and the `midnight` cli:

```sh
go install github.com/taybart/midnight/cmd/midnight@latest
```

## Install

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'taybart/midnight.nvim',
  lazy = false, -- (it's small) for midnight in .rest files
  opts = {},
}
```

Then `:TSInstall midnight` (nvim-treesitter's `main` branch). The parser is
registered when the plugin loads, so to install it w/ the rest of your parsers
make midnight.nvim a dependency of nvim-treesitter:

```lua
{
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  dependencies = { 'taybart/midnight.nvim' },
  config = function() require('nvim-treesitter').install({ 'midnight', ... }) end,
}
```

## Options

```lua
require('midnight').setup({
  cmd = 'midnight',
  -- function markup elements call, passed as `-markup-factory` to lint and
  -- compile (nil: midnight's default, `h`)
  markup_factory = nil,
  -- extra globals for `midnight lint` (or per buffer: vim.b.midnight_globals)
  globals = {},
  treesitter = {
    url = 'https://github.com/taybart/tree-sitter-midnight',
    path = nil, -- a local checkout of the grammar, instead of url
  },
  -- register the formatter / linter if conform / nvim-lint are installed
  conform = true,
  lint = true,
  -- the .mn / .midnight icon, registered w/ nvim-web-devicons if it's
  -- installed (false: don't)
  icon = { glyph = '󰖔', color = '#5b8fd9', cterm_color = '68' },
  -- markup aware commentstrings for `gc`
  comments = true,
  -- lint .rest heredocs, rest's globals in rest projects
  rest = true,
  -- the `vim` global in neovim code (true: detect, false: never, or a
  -- function(buf): boolean)
  nvim = true,
  -- compile on write in projects w/ a midnight.json (see below)
  compile = true,
  -- a quiet "compiled ..." notice when a write changes the output (fidget.nvim
  -- if it's installed, else vim.notify); false: only show compile errors
  compile_notify = true,
})
```

`setup()` adds `midnight_fmt` to conform and `midnight` to nvim-lint (and sets them
for the midnight filetype unless you already have). nvim-lint still needs to be
told when to lint, ex.:

```lua
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
  callback = function() require('lint').try_lint() end,
})
```

To set them up yourself instead (w/ `conform = false, lint = false`):

```lua
require('conform').formatters.midnight_fmt = require('midnight').formatter()
require('lint').linters.midnight = require('midnight').linter()
```

### rest

`.rest` files' `<<MIDNIGHT` heredocs are linted (w/ rest's globals) on read, write,
and leaving insert mode, and `.mn` files in a directory w/ a `.rest` file (or
under one) get rest's globals too (`rest`, `kv`, `json`, ...). Load the plugin
on startup (not `ft = 'midnight'`) so it's there for .rest files. A `.rest`
file counts, a bare `.rest` (ex. rest's `~/.rest`) doesn't.

### Compile on write

In a project w/ a `midnight.json` (see midnight's docs/TOOLS.md), saving a
`.mn` file under its `compile.src` compiles it to the same path under
`compile.out`. Files outside `src` (and projects w/o a `midnight.json`) are left
alone, and compile errors show up w/ `vim.notify`. Ex. a plugin written in
Midnight:

```json
{ "compile": { "src": "midnight", "out": "lua" } }
```

saves `midnight/foo/init.mn` to `lua/foo/init.lua`, which is what neovim
`require`s. `require('midnight').compile_file(buf)` does the same on demand.
After a write that changed the compiled output, a quiet `compiled …` notice
shows (via fidget.nvim's corner window if it's installed, else `vim.notify`);
saving w/o a change stays quiet, and errors use `vim.notify`. Set
`compile_notify = false` to only hear about errors.

### Neovim code

Midnight written for neovim (a plugin, or your config) is linted w/ the `vim`
global, so `vim.api...` isn't an undefined global. A buffer is neovim code
when it's under `stdpath('config')`, or in a runtime directory (`lua/`,
`plugin/`, `ftplugin/`, `after/`, ...) of a project w/ a `lua/` directory,
ex. `foo.nvim/lua/foo/init.mn`, or anywhere in a project whose `midnight.json`
is next to a `lua/` directory (ex. `foo.nvim/midnight/foo/init.mn`). Use `nvim = function(buf) ... end` for your
own rule, or `vim.b.midnight_globals = { 'vim' }` for a one off buffer.

This only covers the linter's undefined global checks: it doesn't know the
`vim` API's shape (lazydev.nvim does that for lua_ls, which doesn't read .mn
files).

## aerial

aerial.nvim's tree-sitter backend picks up `queries/midnight/aerial.scm`, no
setup needed. Outlines show:

| Midnight | Kind |
| --- | --- |
| `class A {}` (any scope) | Class |
| `new()` / `static f()` / `f()` in a class | Constructor / Function / Method |
| `x = 1` in a class | Field |
| `function f()`, `function M.a.b()`, `local f = () -> ...`, `a.b = () -> ...`, `{ f = () -> ... }` | Function |
| `function M:m()` | Method |
| `module x = 1`, `module x` | Variable |

Symbols nest by range (methods under their class, local functions under the
function they're in), and have the declaration's `local` / `global` / `module`
as their scope (ex. to hide locals w/ `post_parse_symbol`). aerial hides
Variables and Fields by default; to show them for midnight:

```lua
require('aerial').setup({
  filter_kind = {
    -- (other filetypes keep aerial's default, or your list as `['_'] = {...}`)
    midnight = { 'Class', 'Constructor', 'Function', 'Method', 'Field', 'Variable' },
  },
})
```

`make test-aerial` checks the symbols for `test/aerial/fixture.mn` against
`test/aerial/expected.txt` (`make update-aerial` rewrites it).
