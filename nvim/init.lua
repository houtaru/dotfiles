-- ~/.config/nvim/init.lua  (Neovim 0.12)

-- ── GLOBALS ───────────────────────────────────────────────────────────────────
vim.g.mapleader      = ","
vim.g.maplocalleader = ","
vim.g.editorconfig = true

-- ── PLUGINS ───────────────────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "tomasiser/vim-code-dark", lazy=false, priority=1000 },
  { "nvim-tree/nvim-web-devicons", lazy=true },

  {
    "saghen/blink.cmp",
    version = "*",
    event   = "InsertEnter",
    opts = {
      keymap = {
        preset = "none",
        ["<C-Space>"] = { "show", "fallback" },
        ["<CR>"]      = { "accept", "fallback" },
        ["<C-e>"]     = { "cancel" },
        ["<Tab>"]     = { "snippet_forward", "fallback" },
        ["<S-Tab>"]   = { "snippet_backward", "fallback" },
        ["<Down>"]     = { "select_next", "fallback_to_mappings" },
        ["<Up>"]     = { "select_prev", "fallback_to_mappings" },
        ["<C-f>"]     = { "scroll_documentation_down", "fallback" },
        ["<C-b>"]     = { "scroll_documentation_up",   "fallback" },
      },
      completion = {
        documentation = {
          auto_show          = true,
          auto_show_delay_ms = 200,
          window             = { border = "rounded" },
        },
        trigger = {
          show_in_snippet = false
        },
        menu = { border = "rounded" },
      },
      sources  = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          markdown = { "lsp", "path", "snippets", "buffer" },
        },
      },
      snippets = { preset = "default" },
      signature = { enabled = true },
    },
  },

  { "nvim-treesitter/nvim-treesitter",
    branch = "main", build = ":TSUpdate",
    event  = "BufReadPost",
    config = function()
      require("nvim-treesitter").setup {}
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      latex = { enabled = true }, -- Performance note: Unicode-based, no external daemon
      debounce = 100,
      render_modes = { "n", "c" },  -- don't render in insert mode
    },
  },

  { "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main", event = "BufReadPost",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup { select = { lookahead = true } }
      local sel = require("nvim-treesitter-textobjects.select")
      local mov = require("nvim-treesitter-textobjects.move")
      local xo  = { "x", "o" }
      local n   = { "n", "x", "o" }
      vim.keymap.set(xo, "af", function() sel.select_textobject("@function.outer","textobjects") end)
      vim.keymap.set(xo, "if", function() sel.select_textobject("@function.inner","textobjects") end)
      vim.keymap.set(n, "]f", function() mov.goto_next_start("@function.outer", "textobjects") end)
      vim.keymap.set(n, "[f", function() mov.goto_previous_start("@function.outer","textobjects") end)
    end,
  },

  { "lewis6991/gitsigns.nvim", event="BufReadPost",
    opts = {
      signs = { add={text="+"}, change={text="~"}, delete={text="_"}, topdelete={text="‾"}, changedelete={text="~"} },
      on_attach = function(buf)
        local gs = package.loaded.gitsigns
        local function m(k, f, d) vim.keymap.set("n", k, f, { buffer=buf, silent=true, desc=d }) end
        m("]h", gs.next_hunk, "Next hunk")
        m("[h", gs.prev_hunk, "Prev hunk")
        m("<leader>hp", gs.preview_hunk, "Preview hunk")
        m("<leader>hs", gs.stage_hunk, "Stage hunk")
        m("<leader>hu", gs.reset_hunk, "Undo/Reset hunk")
      end,
    },
  },

  { "tpope/vim-fugitive",
    cmd = { "Git","Gedit","Gdiffsplit","Gread","Gwrite","GBrowse","G" },
    keys = {
      { "<leader>gh", "<cmd>diffget //2<CR>", mode = { "n", "v" }, desc = "Fugitive: get hunk from LEFT (LOCAL/Target)" },
      { "<leader>gl", "<cmd>diffget //3<CR>", mode = { "n", "v" }, desc = "Fugitive: get hunk from RIGHT (REMOTE/Merge)" },
    },
  },


  { "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen","DiffviewFileHistory","DiffviewClose","DiffviewToggleFiles" },
    opts = { keymaps = { view = { { "n", "q", "<cmd>DiffviewClose<CR>" } } } },
  },

  { "tpope/vim-repeat",     event="VeryLazy" },
  { "kylechui/nvim-surround", event="VeryLazy", config = function() require("nvim-surround").setup() end },
  { "echasnovski/mini.pairs", event="InsertEnter", config = function() require("mini.pairs").setup() end },

  { "stevearc/oil.nvim", lazy=false,
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        skip_confirm_for_simple_edits = true,
        view_options = { show_hidden = true },
        float = { border="rounded" },
        keymaps = {
          ["g?"]   = "actions.show_help",
          ["q"]    = "actions.close",
        },
      })
    end,
  },

  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    cmd = "Obsidian",
    dependencies = { "saghen/blink.cmp" },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "$HOME/code/repo/obsidian-vault",
        },
      },
      daily_notes = {
        folder = "dailies",
        date_format = "%Y-%m-%d",
        template = nil,
      },
      legacy_commands = false,
      ui = { enable = false }, -- Let render-markdown.nvim handle visuals
    },
  },

  { "ibhagwan/fzf-lua", lazy=true,
    keys = {
      { "<C-P>",     function() require("fzf-lua").files() end, desc="Find files" },
      { "<leader>e", function() require("fzf-lua").buffers() end, desc="Buffers" },
      { "<leader>r", function() require("fzf-lua").oldfiles() end, desc="Recent files" },
    },
  },
}, {
  rocks = { enabled = false },
  performance = { rtp = { disabled_plugins = { "gzip","tarPlugin","tohtml","tutor","zipPlugin","netrwPlugin","matchit","matchparen" } } },
})

-- ── OPTIONS ───────────────────────────────────────────────────────────────────
local o = vim.opt
o.number        = true
o.autoindent    = true
o.backspace     = "indent,eol,start"
o.history       = 1000
o.fileencodings = "utf-8"

o.hlsearch      = true; o.incsearch = true; o.ignorecase = true; o.smartcase = true
o.mouse         = "a"
o.textwidth     = 0
o.splitbelow    = true; o.splitright = true
o.foldmethod    = "indent"; o.foldlevel = 20
o.diffopt:append("followwrap,algorithm:histogram,indent-heuristic")
o.autoread      = true; o.autowrite = true
o.showcmd       = true; o.ruler = true
o.timeout       = true; o.timeoutlen = 500
o.visualbell    = true; o.errorbells = false
o.display       = "lastline,uhex"
o.colorcolumn   = "80,100"
o.switchbuf     = "useopen,usetab"
o.backup        = false; o.writebackup = false
o.updatetime    = 250; o.signcolumn = "yes"
o.background    = "dark"
o.termguicolors = true
o.secure        = true
o.exrc          = true
o.scrolloff     = 8; o.sidescrolloff = 8
o.list = true
o.listchars = {
  eol="¬", trail="·", nbsp="◇", tab="→ ",
  extends="▸", precedes="◂", multispace="···⬝", leadmultispace="│   ",
}

-- Relative numbers and CursorLine on focus
local rnu = vim.api.nvim_create_augroup("RelNum", { clear=true })
vim.api.nvim_create_autocmd({"BufEnter","FocusGained","InsertLeave","WinEnter"}, {
    group=rnu,
    callback=function()
        if not vim.wo.number or vim.fn.mode() == "i" then return end
        vim.wo.relativenumber=true
        vim.wo.cursorline=true
    end,
})
vim.api.nvim_create_autocmd({"BufLeave","FocusLost","InsertEnter","WinLeave"}, {
    group=rnu,
    callback=function()
        if not vim.wo.number then return end
        vim.wo.relativenumber=false
        vim.wo.cursorline=false
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("WhitespaceHL", { clear=true }),
  callback = function()
    for _, g in ipairs({ "Whitespace", "NonText", "SpecialKey" }) do
      vim.api.nvim_set_hl(0, g, { fg="#4a4a4a", ctermfg=238, bg="none" })
    end
  end,
})

-- ── DIAGNOSTICS ───────────────────────────────────────────────────────────────
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✘",
      [vim.diagnostic.severity.WARN]  = "▲",
      [vim.diagnostic.severity.INFO]  = "●",
      [vim.diagnostic.severity.HINT]  = "⚑",
    },
  },
  virtual_text = {
    prefix  = "",
    spacing = 2,
    format  = function(d)
      local prefix = ({ "✘ ", "▲ ", "● ", "⚑ " })[d.severity]
      return prefix .. d.message
    end,
  },
  underline        = true,
  update_in_insert = false,
  severity_sort    = true,
  float = { border = "rounded", source = true },
})

-- ── COLORSCHEME ───────────────────────────────────────────────────────────────
vim.cmd.colorscheme("codedark")
local function apply_transparency()
  local clear = { "Normal","NormalNC","NormalFloat","LineNr","SignColumn","VertSplit","WinSeparator","EndOfBuffer","Folded" }
  for _, g in ipairs(clear) do vim.api.nvim_set_hl(0, g, { bg="none", ctermbg="none" }) end
  vim.api.nvim_set_hl(0, "LspInlayHint", { fg="#808080", bg="none", ctermbg="none" })
  -- Use subtle background to reduce underline noise:
  vim.api.nvim_set_hl(0, "CursorLine", { bg="#2a2d2e", ctermbg=236 })
end
apply_transparency()
vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_transparency })

-- ── CLIPBOARD ────────────────────────────────────────────────────────────────
do
  local has_provider = (
    vim.fn.executable("xclip")     == 1 or
    vim.fn.executable("xsel")      == 1 or
    vim.fn.executable("wl-copy")   == 1 or
    vim.fn.executable("pbcopy")    == 1 or
    vim.fn.executable("win32yank") == 1
  )
  if has_provider then
    o.clipboard = "unnamedplus"
  else
    vim.notify(
      "[clipboard] No provider found (xclip/xsel/wl-copy/pbcopy). Install one.",
      vim.log.levels.WARN
    )
  end
end

-- ── NATIVE TMUX NAVIGATION ───────────────────────────────────────────────────
local function tmux_nav(dir)
  local win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. dir)
  if win == vim.api.nvim_get_current_win() then
    local tmux_dir = { h = "L", j = "D", k = "U", l = "R" }
    vim.fn.system("tmux select-pane -" .. tmux_dir[dir])
  end
end
vim.keymap.set({"n","t"}, "<C-h>", function() tmux_nav("h") end, { silent = true })
vim.keymap.set({"n","t"}, "<C-j>", function() tmux_nav("j") end, { silent = true })
vim.keymap.set({"n","t"}, "<C-k>", function() tmux_nav("k") end, { silent = true })
vim.keymap.set({"n","t"}, "<C-l>", function() tmux_nav("l") end, { silent = true })

-- ── NATIVE STATUSLINE ─────────────────────────────────────────────────────────
function _G.statusline()
  local mode = vim.api.nvim_get_mode().mode:sub(1,1)
  local file = vim.fn.expand("%:p:~:.")
  local git = vim.b.gitsigns_status_dict
  local git_str = git and string.format(" [%s +%s ~%s]", git.head or "?", git.added or 0, git.changed or 0) or ""
  local diag = vim.diagnostic.count(0)
  local e, w = diag[1] or 0, diag[2] or 0
  local diag_str = (e > 0 or w > 0) and string.format(" E:%d W:%d", e, w) or ""
  return string.format(" %s | %s%s%s %%= %s | %d:%d ", mode, file, git_str, diag_str, vim.bo.filetype, vim.fn.line("."), vim.fn.col("."))
end
o.statusline = "%!v:lua.statusline()"
o.laststatus = 3

-- ── NATIVE LSP (0.12) ────────────────────────────────────────────────────────
vim.lsp.config("*", {
  capabilities = (function()
    local ok, blink = pcall(require, "blink.cmp")
    return ok and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()
  end)(),
  exit_timeout = 1000,
  root_markers = { ".git", "tags"},
})

vim.lsp.config("lua_ls", { settings = { Lua = { diagnostics = { globals = { "vim" } } } } })
vim.lsp.config("rust_analyzer", { cmd = { "rust-analyzer" } })
vim.lsp.config("gopls",         { cmd = { "gopls" } })
vim.lsp.config("pyright",       { cmd = { "pyright-langserver", "--stdio" } })
vim.lsp.config("clangd", {
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    cmd = { "clangd"
        , "-j=2"
        , "--background-index"
        , "--clang-tidy"
        , "--header-insertion=iwyu"
        , "--all-scopes-completion"
        , "--limit-references=100"
        , "--query-driver=/usr/bin/g++"
    },
})

vim.o.tagfunc = "v:lua.vim.lsp.tagfunc"

vim.api.nvim_create_autocmd("LspAttach", {
  group    = vim.api.nvim_create_augroup("LspAttach", { clear=true }),
  callback = function(ev)
    local buf = ev.buf
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local is_file = vim.uri_from_bufnr(buf):match("^file://") ~= nil
    if is_file and client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
      vim.lsp.inlay_hint.enable(true, { bufnr = buf })
    end

    local m   = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer=buf, silent=true, desc=desc })
    end

    m("n", "gd",                vim.lsp.buf.definition,                "Go to definition")
    m("n", "gy",                vim.lsp.buf.type_definition,           "Go to type definition")
    m("n", "gi",                vim.lsp.buf.implementation,            "Go to implementation")
    m({"n","v"}, "<leader>ca",  vim.lsp.buf.code_action,               "Code action")
    m("n", "<leader>cr",        vim.lsp.buf.rename,                    "Rename symbol")
    m("n", "gr",                vim.lsp.buf.references,                "List references")
    m("n", "K",                 vim.lsp.buf.hover,                     "Hover docs")
    m("n", "gl",                vim.diagnostic.open_float,             "Diagnostic info")
    m("n", "[g", function() vim.diagnostic.jump({count = -1, float = true}) end, "Prev diagnostic")
    m("n", "]g", function() vim.diagnostic.jump({count = 1, float = true}) end, "Next diagnostic")
    m("n", "<leader>dd", function()
      local enabled = vim.diagnostic.is_enabled({ bufnr=buf })
      vim.diagnostic.enable(not enabled, { bufnr=buf })
    end, "Toggle diagnostics (buffer)")

    m("n", "<leader>dq", function() vim.diagnostic.setqflist({ open = true, bufnr = 0 }) end, "Diagnostics to quickfix (current file)")
    m("n", "<leader>dQ", function() vim.diagnostic.setqflist({ open = true }) end, "Diagnostics to quickfix (buffer)")

    -- Document highlight on CursorHold (replaces coc highlight)
    -- Scoped augroup per buffer avoids accumulation on many open files.
    if is_file and client and client.server_capabilities.documentHighlightProvider then
      local augrp = vim.api.nvim_create_augroup("LspDocHL_"..buf, { clear=true })
      vim.api.nvim_create_autocmd("CursorHold", {
        buffer   = buf,
        group    = augrp,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({"CursorMoved","InsertEnter"}, {
        buffer   = buf,
        group    = augrp,
        callback = vim.lsp.buf.clear_references,
      })
    end
    end,
    })
-- ── QUICKFIX & SEARCH ─────────────────────────────────────────────────────────
local function qf_open()
  for _, w in ipairs(vim.fn.getwininfo()) do if w.quickfix == 1 then return true end end
  return false
end
local function qf_in_tab()
  for _, b in ipairs(vim.fn.tabpagebuflist()) do
    if vim.bo[b].buftype == "quickfix" then return true end
  end
  return false
end

local function rg_qf(pattern, extra_flags, title)
  if not pattern or pattern == "" then
    vim.notify("Rg: missing pattern", vim.log.levels.WARN); return
  end
  local args = { "rg","--column","--line-number","--no-heading","--smart-case" }

  local ec = vim.b.editorconfig or {}
  if ec.exclude_ignorefiles == "false" then
    table.insert(args, "--no-ignore")
  end
  if ec.exclude_hidden == "false" then
    table.insert(args, "--hidden")
  end
  if ec.exclude_files and ec.exclude_files ~= "" then
    for pat in ec.exclude_files:gmatch("[^,]+") do
      pat = vim.trim(pat)
      if pat ~= "" then
        table.insert(args, "-g")
        table.insert(args, "!" .. pat)
      end
    end
  end

  for _, f in ipairs(extra_flags or {}) do table.insert(args, f) end
  table.insert(args, "--"); table.insert(args, pattern)
  vim.system(args, { text=true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 and (not result.stdout or result.stdout=="") then
        vim.notify("Rg: no results for "..pattern, vim.log.levels.INFO); return
      end
      vim.fn.setqflist({}, "r", {
        lines = vim.split(result.stdout or "", "\n", { trimempty=true }),
        title = title or (":Rg "..pattern),
      })
      vim.cmd("copen | wincmd p")
    end)
  end)
end

vim.keymap.set("n", "<leader>q", function() vim.cmd(qf_open() and "cclose" or "copen") end,
  { silent=true, desc="KEYMAPS: toggle quickfix" })
vim.keymap.set("n", "<leader>n", function() vim.cmd(qf_in_tab() and "cnext" or "bnext") end,
  { desc="KEYMAPS: next qf item / buffer" })
vim.keymap.set("n", "<leader>b", function() vim.cmd(qf_in_tab() and "cprev" or "bprev") end,
  { desc="KEYMAPS: prev qf item / buffer" })

vim.keymap.set("n", "g]", function()
  local w = vim.fn.expand("<cword>")
  local t = vim.fn.taglist("^"..w.."$")
  if #t == 0 then return vim.notify("No tags: "..w, 2) end
  local items = {}
  for _, v in ipairs(t) do
    table.insert(items, { filename=v.filename, text=v.name, lnum=tonumber(v.cmd), pattern=not tonumber(v.cmd) and v.cmd:sub(2,-2) or nil })
  end
  vim.fn.setqflist({}, "r", { title="Tags: "..w, items=items })
  vim.cmd("copen")
end, { desc="Search tags to quickfix" })

vim.keymap.set("n", "gw", function()
  rg_qf(vim.fn.expand("<cword>"))
end, { desc = "Search word under cursor to quickfix" })

vim.keymap.set("v", "gw", function()
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
  if #lines == 0 then return end
  local pattern = table.concat(lines, "\n")
  local flags = { "-F" }
  if #lines > 1 then table.insert(flags, "-U") end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  rg_qf(pattern, flags, "Visual Search")
end, { desc = "Search selection to quickfix" })

vim.api.nvim_create_user_command("Rg", function(opts) rg_qf(opts.args, {}) end, { nargs="+" })

-- ── KEYMAPS ───────────────────────────────────────────────────────────────────
vim.keymap.set("n", "<leader>yf", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, { desc="Yank path" })
vim.keymap.set("n", "<C-N>", function() require("oil").toggle_float() end, { silent=true })

vim.keymap.set("n", "<leader>v", "<cmd>vsplit<CR>")
vim.keymap.set("n", "<leader>s", "<cmd>split<CR>")
vim.keymap.set('n', '<leader>=', '<C-w>=', { desc = 'Make windows equal size' })
vim.keymap.set("n", "<leader>w", "<cmd>bw<CR>", { desc = "Close buffer" })

vim.keymap.set("n", "<leader>gf", function()
  local params = { textDocument = vim.lsp.util.make_text_document_params() }
  vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result)
    if err or not result then return print("No function found") end
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local path = {}
    local function walk(syms)
      for _, s in ipairs(syms) do
        local r = s.range or (s.location and s.location.range)
        if r and r.start.line <= row and r["end"].line >= row then
          -- 3:Namespace, 5:Class, 6:Method, 11:Interface, 12:Function, 23:Struct
          if s.kind == 3 or s.kind == 5 or s.kind == 6 or s.kind == 11 or s.kind == 12 or s.kind == 23 then
            table.insert(path, s.name)
          end
          if s.children then walk(s.children) end
          return
        end
      end
    end
    walk(result)
    if #path > 0 then
      local msg = table.concat(path, "::")
      vim.notify(msg)
      vim.fn.setreg("+", msg)
    else
      vim.notify("No function context")
    end
  end)
end, { desc = "Print function context (LSP)" })

-- ── FILETYPES ────────────────────────────────────────────────────────────────
vim.filetype.add({
  extension = {
    py2 = "python",
    tla = "tla",
  }
})

-- ── EDITORCONFIG ──────────────────────────────────────────────────────────────
local function ec_prop(name, default)
  require("editorconfig").properties[name] = function(bufnr, val)
    vim.b[bufnr].editorconfig = vim.tbl_extend("keep", vim.b[bufnr].editorconfig or {}, { [name] = val or default })
  end
end

ec_prop("enable_lsp",            "true")
ec_prop("exclude_ignorefiles",   "true")
ec_prop("exclude_hidden",        "true")
ec_prop("exclude_files",         "")
ec_prop("container_name",        "")

-- ── CONTAINER LSP FILE CACHE ─────────────────────────────────────────────────
-- Intercepts LSP jumps to remote files and locally caches them in $PWD/.cache/
local function sync_container_file(name, path)
  local container_cmd = vim.env.CONTAINER_COMMAND
  if not container_cmd or container_cmd == "" then return nil end

  local cache_path = vim.fn.getcwd() .. "/.cache/container/" .. name .. path
  if vim.fn.filereadable(cache_path) == 1 then return cache_path end

  local res = vim.system({ container_cmd, "exec", "-i", name, "cat", path }, { text = true }):wait()
  if res.code ~= 0 then return nil end

  local lines = {}
  if res.stdout and res.stdout ~= "" then
    lines = vim.split(res.stdout, "\n")
    if #lines > 0 and lines[#lines] == "" then
      table.remove(lines)
    end
  end
  vim.fn.mkdir(vim.fn.fnamemodify(cache_path, ":h"), "p")
  vim.fn.writefile(lines, cache_path)
  return cache_path
end

local orig_uri_to_fname = vim.uri_to_fname
vim.uri_to_fname = function(uri)
  local path = orig_uri_to_fname(uri)
  if not uri:match("^file://") then return path end

  local buf = vim.api.nvim_get_current_buf()
  local name = vim.b[buf].editorconfig and vim.b[buf].editorconfig.container_name
  if not name or name == "" then return path end

  local cwd = vim.fn.getcwd()
  if path == cwd or vim.startswith(path, cwd .. "/") then return path end

  return sync_container_file(name, path) or path
end

-- ── CONTAINER LSP ─────────────────────────────────────────────────────────────
local function lsp_cmd(server, cmd, bufnr)
  local name = (vim.b[bufnr].editorconfig or {}).container_name
  local container_cmd = vim.env.CONTAINER_COMMAND

  if not name or name == "" or not container_cmd or container_cmd == "" then
    return cmd
  end

  local wrapped = { container_cmd, "exec", "-i", name }
  for _, arg in ipairs(cmd) do table.insert(wrapped, arg) end
  return wrapped
end

-- ── LANGUAGE SETTINGS ─────────────────────────────────────────────────────────

local function set_rg(ft, flags)
  vim.api.nvim_buf_create_user_command(0, "Rg", function(opts)
    rg_qf(opts.args, flags, (":Rg(%s) %s"):format(ft, opts.args))
  end, { nargs = "+", desc = "Rg scoped to " .. ft })
  vim.keymap.set("n", "gw", function()
    rg_qf(vim.fn.expand("<cword>"), flags, (":Rg(%s) %s"):format(ft, vim.fn.expand("<cword>")))
  end, { buffer = 0, desc = "Search word under cursor to quickfix (scoped)" })
  vim.keymap.set("v", "gw", function()
    local sel = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
    if #sel == 0 then return end
    local pattern = table.concat(sel, "\n")
    local f = vim.deepcopy(flags or {})
    table.insert(f, "-F")
    if #sel > 1 then table.insert(f, "-U") end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    rg_qf(pattern, f, (":Rg(%s) Visual"):format(ft))
  end, { buffer = 0, desc = "Search selection to quickfix (scoped)" })
end

local function enable_lsp(server, bufnr)
  local cfg = vim.lsp.config[server] or {}
  local base_cmd = cfg.cmd
  if not base_cmd then
    vim.lsp.enable(server)
    return
  end
  local cmd = lsp_cmd(server, base_cmd, bufnr)
  if not cmd then return end
  local override = { cmd = cmd }
  if cmd ~= base_cmd then
    override.before_init = function(params) params.processId = vim.NIL end
  end
  vim.lsp.config(server, override)
  vim.lsp.enable(server)
end

local ft = {}

ft.c = function(ev)
  set_rg("c/cpp", { "--type", "c", "--type", "cpp"})
  enable_lsp("clangd", ev.buf)
end
ft.cpp = ft.c

ft.java = function()
  set_rg("java", {"--type", "java"})
end

ft.rust = function(ev)
  enable_lsp("rust_analyzer", ev.buf)
end

ft.go = function(ev)
  enable_lsp("gopls", ev.buf)
end

ft.python = function(ev)
  enable_lsp("pyright", ev.buf)
end

ft.lua = function(ev)
  enable_lsp("lua_ls", ev.buf)
end

local ts_required_parsers = { c=true, cpp=true, rust=true, go=true, bash=true, python=true, lua=true, json=true, yaml=true, toml=true, cmake=true, markdown=true, markdown_inline=true, latex=true }

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("LangSettings", { clear = true }),
  callback = function(ev)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then return end
      if not vim.uri_from_bufnr(ev.buf):match("^file://") then return end

      -- Native treesitter highlighting fallback
      local ok = pcall(vim.treesitter.start, ev.buf)
      if not ok then
        local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
        if ts_required_parsers[lang] then
          vim.notify("Missing Tree-sitter parser for '" .. lang .. "'. Run ':TSInstall " .. lang .. "' to install it.", vim.log.levels.WARN)
        end
      end

      local b = vim.b[ev.buf]
      if b.editorconfig and b.editorconfig.enable_lsp == "false" then return end
      if ft[ev.match] then ft[ev.match](ev) end
    end)
  end
})
