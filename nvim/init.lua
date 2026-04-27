-- ~/.config/nvim/init.lua  (Neovim 0.12)

-- ── LEADER ───────────────────────────────────────────────────────────────────
vim.g.mapleader      = ","
vim.g.maplocalleader = ","

-- ── OPTIONS ───────────────────────────────────────────────────────────────────
local o = vim.opt
o.number        = true
o.autoindent    = true
o.shiftwidth    = 4; o.softtabstop = 4; o.tabstop = 4; o.expandtab = true
o.backspace     = "indent,eol,start"
o.history       = 1000

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

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("WhitespaceHL", { clear=true }),
  callback = function()
    for _, g in ipairs({ "Whitespace", "NonText", "SpecialKey" }) do
      vim.api.nvim_set_hl(0, g, { fg="#4a4a4a", ctermfg=238, bg="none" })
    end
  end,
})

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

-- ── PLUGINS ───────────────────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
o.rtp:prepend(lazypath)

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
        ["<Tab>"]     = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"]   = { "select_prev", "snippet_backward", "fallback" },
        ["<CR>"]      = { "accept", "fallback" },
        ["<C-e>"]     = { "cancel" },
        ["<C-f>"]     = { "scroll_documentation_down", "fallback" },
        ["<C-b>"]     = { "scroll_documentation_up",   "fallback" },
      },
      completion = {
        documentation = {
          auto_show          = true,
          auto_show_delay_ms = 200,
          window             = { border = "rounded" },
        },
        menu = { border = "rounded" },
      },
      sources  = { default = { "lsp", "path", "snippets", "buffer" } },
      snippets = { preset = "default" },
      signature = { enabled = true },
    },
  },

  { "nvim-treesitter/nvim-treesitter",
    branch = "main", build = ":TSUpdate",
    event  = "BufReadPost",
    config = function()
      require("nvim-treesitter").setup {
        ensure_installed = { "c", "cpp", "rust", "go", "bash", "python", "lua", "json", "yaml", "toml", "cmake", "tlaplus" },
        auto_install = false,
      }
    end,
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

  { "tpope/vim-fugitive", cmd = { "Git","Gedit","Gdiffsplit","Gread","Gwrite","GBrowse","G" } },

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
    local m   = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer=buf, silent=true, desc=desc })
    end

    -- Navigation with ctag/fzf fallback
    local function nav(method)
      return function()
        local client = vim.lsp.get_clients({ bufnr = 0, method = method })[1]
        local params = vim.lsp.util.make_position_params(0, client and client.offset_encoding or "utf-16")
        vim.lsp.buf_request(0, method, params, function(err, result, ctx)
          if err or not result or (vim.islist(result) and #result == 0) then
            local word = vim.fn.expand("<cword>")
            if vim.fn.taglist("^"..word.."$")[1] then
              require("fzf-lua").tags({ search=word })
            else
              vim.fn.searchdecl(word)
            end
            return
          end

          local client = vim.lsp.get_client_by_id(ctx.client_id)
          local enc = client and client.offset_encoding or "utf-16"
          local location = vim.islist(result) and result[1] or result

          vim.lsp.util.show_document(location, enc, { focus = true })
        end)
      end
    end

    m("n", "gd", nav("textDocument/definition"), "Go to definition")
    m("n", "gy", nav("textDocument/typeDefinition"), "Go to type definition")
    m("n", "gi", nav("textDocument/implementation"), "Go to implementation")
    m("n", "gr", vim.lsp.buf.references,         "List references")
    m("n", "K",  vim.lsp.buf.hover,              "Hover docs")
    m("n", "[g", vim.diagnostic.goto_prev,            "Prev diagnostic")
    m("n", "]g", vim.diagnostic.goto_next,            "Next diagnostic")
    m("n", "gl", vim.diagnostic.open_float,      "Diagnostic info")
    m({"n","v"}, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    m("n", "<leader>cr", vim.lsp.buf.rename,      "Rename symbol")
    m("n", "<leader>dd", function()
      local enabled = vim.diagnostic.is_enabled({ bufnr=buf })
      vim.diagnostic.enable(not enabled, { bufnr=buf })
    end, "KEYMAPS: toggle diagnostics (buffer)")

    -- Document highlight on CursorHold (replaces coc highlight)
    -- Scoped augroup per buffer avoids accumulation on many open files.
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

vim.keymap.set("n", "<leader>q", function() vim.cmd(qf_open() and "cclose" or "copen") end,
  { silent=true, desc="KEYMAPS: toggle quickfix" })
vim.keymap.set("n", "<leader>n", function() vim.cmd(qf_in_tab() and "cnext" or "bnext") end,
  { desc="KEYMAPS: next qf item / buffer" })
vim.keymap.set("n", "<leader>b", function() vim.cmd(qf_in_tab() and "cprev" or "bprev") end,
  { desc="KEYMAPS: prev qf item / buffer" })

local function rg_qf(pattern, extra_flags, title)
  if not pattern or pattern == "" then
    vim.notify("Rg: missing pattern", vim.log.levels.WARN); return
  end
  local args = { "rg","--column","--line-number","--no-heading","--smart-case" }
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

vim.api.nvim_create_user_command("Rg", function(opts) rg_qf(opts.args, {}) end, { nargs="+" })
vim.cmd("cabbrev rg Rg")

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- ── KEYMAPS ───────────────────────────────────────────────────────────────────
vim.keymap.set("n", "<leader>yf", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, { desc="Yank path" })
vim.keymap.set("n", "<C-N>", function() require("oil").toggle_float() end, { silent=true })
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<CR>")
vim.keymap.set("n", "<leader>s", "<cmd>split<CR>")

-- ── FILETYPES ────────────────────────────────────────────────────────────────
vim.filetype.add({
  extension = {
    py2 = "python",
    tla = "tla",
  }
})

-- ── LANGUAGE SETTINGS ─────────────────────────────────────────────────────────
local function set_tabs(n, expand)
  vim.bo.tabstop, vim.bo.softtabstop, vim.bo.shiftwidth, vim.bo.expandtab = n, n, n, expand
end

local function set_rg(ft, flags)
  vim.api.nvim_buf_create_user_command(0, "Rg", function(opts)
    rg_qf(opts.args, flags, (":Rg(%s) %s"):format(ft, opts.args))
  end, { nargs = "+", desc = "Rg scoped to " .. ft })
end

local ft = {}

ft.c = function()
  set_tabs(4, false)
  set_rg("c/cpp", { "--type", "c", "--type", "cpp", "-g", "!thrift", "-g", "!thriftzg" })
  vim.lsp.enable("clangd")
end
ft.cpp = ft.c

ft.java = function()
  set_tabs(2, false)
  set_rg("java", {"--type", "java", "-g", "!thrift", "-g", "!thriftzg"})
end

ft.rust = function()
  set_tabs(2, false)
  vim.lsp.enable("rust-analyzer")
end

ft.go = function()
  set_tabs(4, false)
  vim.lsp.enable("gopls")
end

ft.python = function()
  vim.lsp.enable("pyright")
end

ft.lua = function()
  set_tabs(2, true)
  vim.lsp.enable("lua_ls")
end

ft.sh  = function() set_tabs(2, true) end
ft.vim = function() set_tabs(2, true) end
ft.tla = function() set_tabs(2, true) end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("LangSettings", { clear = true }),
  callback = function(ev) if ft[ev.match] then ft[ev.match](ev) end end
})

-- Relative numbers on focus
local rnu = vim.api.nvim_create_augroup("RelNum", { clear=true })
vim.api.nvim_create_autocmd({"BufEnter","FocusGained","InsertLeave","WinEnter"}, { group=rnu, callback=function() if vim.wo.number and vim.fn.mode()~="i" then vim.wo.relativenumber=true end end })
vim.api.nvim_create_autocmd({"BufLeave","FocusLost","InsertEnter","WinLeave"}, { group=rnu, callback=function() if vim.wo.number then vim.wo.relativenumber=false end end })

-- ── SNIPPETS / TEMPLATES ─────────────────────────────────────────────────────
local function snip_dir() return vim.fn.stdpath("config").."/snippets" end
local function apply_template(path)
  if vim.fn.filereadable(path)==0 then return end
  local out, cursor = {}, {0,0}
  local author = vim.trim(vim.fn.system("git config user.name"))
  local classname = vim.fn.expand("%:t:r"):gsub("^%l", string.upper)
  for row, line in ipairs(vim.fn.readfile(path)) do
    line = line:gsub("{{FILE}}", vim.fn.expand("%:t")):gsub("{{AUTHOR}}", author):gsub("{{DATE}}", vim.fn.strftime("%B %d, %Y")):gsub("{{CLASS}}", classname)
    local ci = line:find("{{CURSOR}}")
    if ci then cursor={row,ci}; line=line:gsub("{{CURSOR}}","") end
    table.insert(out, line)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
  if cursor[1]~=0 then vim.fn.cursor(cursor[1], cursor[2]) end
end

vim.api.nvim_create_user_command("Snipcode", function(opts)
  local ft = opts.args~="" and opts.args or vim.bo.filetype
  apply_template(snip_dir().."/template."..ft)
end, { nargs="?" })

-- ── COLORSCHEME ───────────────────────────────────────────────────────────────
vim.cmd.colorscheme("codedark")
local function apply_transparency()
  local clear = { "Normal","NormalNC","NormalFloat","LineNr","SignColumn","VertSplit","WinSeparator","EndOfBuffer" }
  for _, g in ipairs(clear) do vim.api.nvim_set_hl(0, g, { bg="none", ctermbg="none" }) end
end
apply_transparency()
vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_transparency })
