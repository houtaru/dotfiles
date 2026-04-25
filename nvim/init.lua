-- ~/.config/nvim/init.lua

-- ── LEADER ───────────────────────────────────────────────────────────────────
vim.g.mapleader      = ","
vim.g.maplocalleader = ","

-- ── NODE PATH (coc.nvim) ─────────────────────────────────────────────────────
local function find_node()
  local e = vim.env.COC_NODE_PATH
  if e and vim.fn.executable(e) == 1 then return e end
  if vim.env.APPDIR then
    local p = vim.env.APPDIR .. "/usr/bin/node"
    if vim.fn.executable(p) == 1 then return p end
  end
  local p = vim.fn.exepath("node")
  return p ~= "" and p or nil
end
vim.g.coc_node_path = find_node()

-- ── OPTIONS ───────────────────────────────────────────────────────────────────
local o = vim.opt
o.number        = true
o.autoindent    = true
o.shiftwidth    = 4; o.softtabstop = 4; o.tabstop = 4; o.expandtab = false
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
      "[clipboard] No provider found (xclip/xsel/wl-copy/pbcopy). Install one to enable sync.",
      vim.log.levels.WARN
    )
  end
end

-- ── PLUGINS ───────────────────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
o.rtp:prepend(lazypath)

require("lazy").setup({

  { "tomasiser/vim-code-dark", lazy=false, priority=1000 },

  { "neoclide/coc.nvim", branch="release", event="BufReadPost" },

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
    branch = "main",
    event  = "BufReadPost",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup { select = { lookahead = true } }

      local sel = require("nvim-treesitter-textobjects.select")
      local mov = require("nvim-treesitter-textobjects.move")
      local swp = require("nvim-treesitter-textobjects.swap")
      local xo  = { "x", "o" }
      local n   = { "n", "x", "o" }

      vim.keymap.set(xo, "af", function() sel.select_textobject("@function.outer","textobjects") end, { desc="KEYMAPS: around function" })
      vim.keymap.set(xo, "if", function() sel.select_textobject("@function.inner","textobjects") end, { desc="KEYMAPS: inner function" })
      vim.keymap.set(xo, "ac", function() sel.select_textobject("@class.outer",   "textobjects") end, { desc="KEYMAPS: around class" })
      vim.keymap.set(xo, "ic", function() sel.select_textobject("@class.inner",   "textobjects") end, { desc="KEYMAPS: inner class" })

      vim.keymap.set(n, "]f", function() mov.goto_next_start("@function.outer",    "textobjects") end, { desc="KEYMAPS: next function start" })
      vim.keymap.set(n, "[f", function() mov.goto_previous_start("@function.outer","textobjects") end, { desc="KEYMAPS: prev function start" })
      vim.keymap.set(n, "]F", function() mov.goto_next_end("@function.outer",      "textobjects") end, { desc="KEYMAPS: next function end" })
      vim.keymap.set(n, "[F", function() mov.goto_previous_end("@function.outer",  "textobjects") end, { desc="KEYMAPS: prev function end" })
      vim.keymap.set(n, "]C", function() mov.goto_next_end("@class.outer",         "textobjects") end, { desc="KEYMAPS: next class end" })
      vim.keymap.set(n, "[C", function() mov.goto_previous_end("@class.outer",     "textobjects") end, { desc="KEYMAPS: prev class end" })

      vim.keymap.set(n, "<leader>sn", function() swp.swap_next("@parameter.inner","textobjects") end,     { desc="KEYMAPS: swap arg →" })
      vim.keymap.set(n, "<leader>sp", function() swp.swap_previous("@parameter.inner","textobjects") end, { desc="KEYMAPS: swap arg ←" })
    end,
  },

  -- ── GIT ──────────────────────────────────────────────────────────────────
  { "lewis6991/gitsigns.nvim", event="BufReadPost",
    opts = {
      signs = { add={text="+"}, change={text="~"}, delete={text="_"},
                topdelete={text="‾"}, changedelete={text="~"} },
      on_attach = function(buf)
        local bt  = vim.bo[buf].buftype
        local win = vim.fn.bufwinid(buf)
        local in_diff_win = bt == "nofile" and win ~= -1 and vim.wo[win].diff
        local is_dv_panel = vim.b[buf].diffview_view_initialized ~= nil
        local is_fugitive = vim.fn.bufname(buf):match("^fugitive://") ~= nil
        if in_diff_win or is_dv_panel or is_fugitive then return end

        local function gs() return package.loaded.gitsigns end
        local function m(k, f, d)
          vim.keymap.set("n", k, f, { buffer=buf, silent=true, desc=d })
        end

        m("]h", function() local g=gs(); if g then g.next_hunk() end end,              "KEYMAPS: next git hunk")
        m("[h", function() local g=gs(); if g then g.prev_hunk() end end,              "KEYMAPS: prev git hunk")
        m("<leader>hp", function() local g=gs(); if g then g.preview_hunk() end end,   "KEYMAPS: preview hunk inline")
        m("<leader>hs", function() local g=gs(); if g then g.stage_hunk() end end,     "KEYMAPS: stage hunk")
        m("<leader>hS", function() local g=gs(); if g then g.stage_buffer() end end,   "KEYMAPS: stage entire buffer")
        m("<leader>hu", function() local g=gs(); if g then g.reset_hunk() end end,     "KEYMAPS: undo/reset hunk")
        m("<leader>hb", function() local g=gs(); if g then g.blame_line({full=true}) end end, "KEYMAPS: blame line")
      end,
    },
  },

  { "tpope/vim-fugitive",
    cmd = { "Git","Gedit","Gdiffsplit","Gread","Gwrite","GBrowse","G" },
  },

  { "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen","DiffviewFileHistory","DiffviewClose","DiffviewToggleFiles" },
    opts = function()
      local actions = require("diffview.actions")
      return {
        keymaps = {
          view = {
            { "n", "]h", "]c",                      { desc="KEYMAPS: diffview next diff hunk" } },
            { "n", "[h", "[c",                      { desc="KEYMAPS: diffview prev diff hunk" } },
            { "n", "]c", "]c",                      { desc="KEYMAPS: diffview next diff hunk (alt)" } },
            { "n", "[c", "[c",                      { desc="KEYMAPS: diffview prev diff hunk (alt)" } },
            { "n", "q",  "<cmd>DiffviewClose<CR>",  { desc="KEYMAPS: close diffview" } },
            { "n", "<leader>hs", actions.stage_all, { desc="KEYMAPS: stage file in diffview" } },
          },
          file_panel = {
            { "n", "]h", actions.select_next_entry,  { desc="KEYMAPS: diffview next file" } },
            { "n", "[h", actions.select_prev_entry,  { desc="KEYMAPS: diffview prev file" } },
            { "n", "s",  actions.toggle_stage_entry, { desc="KEYMAPS: stage/unstage file" } },
            { "n", "q",  "<cmd>DiffviewClose<CR>",   { desc="KEYMAPS: close diffview" } },
          },
          file_history_panel = {
            { "n", "]h", actions.select_next_entry, { desc="KEYMAPS: diffview next entry" } },
            { "n", "[h", actions.select_prev_entry, { desc="KEYMAPS: diffview prev entry" } },
            { "n", "q",  "<cmd>DiffviewClose<CR>",  { desc="KEYMAPS: close diffview" } },
          },
        },
      }
    end,
  },

  { "tpope/vim-repeat",     event="VeryLazy" },
  { "tpope/vim-commentary", event="VeryLazy" },
  { "kylechui/nvim-surround", event="VeryLazy",
    config = function() require("nvim-surround").setup() end },
  { "echasnovski/mini.pairs", event="InsertEnter",
    config = function() require("mini.pairs").setup() end },

  { "stevearc/oil.nvim", lazy=false,
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        buf_options = { buflisted = false, bufhidden = "hide" },
        delete_to_trash = false,
        skip_confirm_for_simple_edits = true,
        view_options = { show_hidden = true },
        float = { padding=2, max_width=80, max_height=30, border="rounded" },
        keymaps = {
          ["g?"]   = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["-"]    = "actions.parent",
          ["_"]    = "actions.open_cwd",
          ["gs"]   = "actions.change_sort",
          ["gx"]   = "actions.open_external",
          ["g."]   = "actions.toggle_hidden",
          ["q"]    = "actions.close",
        },
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern  = "oil",
        group    = vim.api.nvim_create_augroup("OilNoAutowrite", { clear=true }),
        callback = function() vim.opt_local.autowrite = false end,
      })
    end,
  },

  { "nvim-lualine/lualine.nvim", event="VeryLazy",
    opts = {
      options = { theme="codedark", globalstatus=true,
                  component_separators={left="",right=""},
                  section_separators={left="",right=""} },
      sections = {
        lualine_a = { { "mode", fmt=function(s) return s:sub(1,1) end } },
        lualine_b = { "branch","diff","diagnostics" },
        lualine_c = { { "filename", path=1 },
                      { function() return vim.b.coc_current_function or "" end } },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  { "ibhagwan/fzf-lua", lazy=true,
    keys = {
      { "<C-P>",     function() require("fzf-lua").files() end,                                   desc="KEYMAPS: find files" },
      { "<leader>p", function() require("fzf-lua").files({ cwd=vim.fn.expand("%:p:h") }) end,     desc="KEYMAPS: find files (here)" },
      { "<leader>e", function() require("fzf-lua").buffers() end,                                 desc="KEYMAPS: switch buffer" },
      { "<leader>r", function() require("fzf-lua").oldfiles() end,                                desc="KEYMAPS: recent files" },
      { "g]",        function() require("fzf-lua").tags({ search=vim.fn.expand("<cword>") }) end, desc="KEYMAPS: ctag jump (fzf)" },
    },
    config = function()
      require("fzf-lua").setup({
        winopts  = { height=0.85, width=0.80, preview={ layout="vertical", vertical="down:40%" } },
        fzf_opts = { ["--layout"]="reverse" },
      })
    end,
  },

  { "alexghergh/nvim-tmux-navigation", event="VeryLazy",
    config = function()
      local nav = require("nvim-tmux-navigation")
      nav.setup({ disable_when_zoomed=true })
      local m = function(k, f) vim.keymap.set({"n","t"}, k, f, { silent=true }) end
      m("<C-h>", nav.NvimTmuxNavigateLeft);  m("<C-j>", nav.NvimTmuxNavigateDown)
      m("<C-k>", nav.NvimTmuxNavigateUp);    m("<C-l>", nav.NvimTmuxNavigateRight)
      m("<C-\\>", nav.NvimTmuxNavigateLastActive)
    end,
  },

}, {
  rocks = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
        "netrwPlugin", "netrw", "netrwSettings", "netrwFileHandlers",
        "matchit", "matchparen",
      },
    },
  },
})

-- Re-run BufReadPost for any buffer already loaded at startup.
vim.api.nvim_create_autocmd("VimEnter", { once=true, callback=function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_exec_autocmds("BufReadPost", { buffer=buf })
    end
  end
end })

-- ── COLORSCHEME ───────────────────────────────────────────────────────────────
vim.cmd.colorscheme("codedark")

local function apply_transparency()
  local clear_bg = {
    "Normal", "NormalNC", "NormalFloat",
    "LineNr", "LineNrAbove", "LineNrBelow", "CursorLineNr",
    "SignColumn", "FoldColumn",
    "StatusLine", "StatusLineNC", "StatusLineTerm", "StatusLineTermNC",
    "VertSplit", "WinSeparator",
    "TabLine", "TabLineFill", "TabLineSel",
    "EndOfBuffer",
  }
  for _, g in ipairs(clear_bg) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name=g, link=false })
    if ok then
      hl.bg    = nil
      hl.ctermbg = nil
      vim.api.nvim_set_hl(0, g, hl)
    else
      vim.api.nvim_set_hl(0, g, { bg="none", ctermbg="none" })
    end
  end
end

apply_transparency()

local function apply_folded_hl()
  vim.api.nvim_set_hl(0, "Folded", { fg="#7a9ec2", bg="#1e2a35", italic=true, ctermfg=67, ctermbg=236 })
end
apply_folded_hl()

vim.api.nvim_create_autocmd("ColorScheme", {
  group    = vim.api.nvim_create_augroup("CodeDarkTransparent", { clear=true }),
  callback = apply_transparency,
})
vim.api.nvim_create_autocmd("ColorScheme", {
  group    = vim.api.nvim_create_augroup("FoldedHL", { clear=true }),
  callback = apply_folded_hl,
})

if (vim.env.TERM or ""):match("^screen") then
  vim.keymap.set({"n","v"}, "~", "<Nop>")
end

-- ── COC.NVIM ──────────────────────────────────────────────────────────────────
vim.o.tagfunc = "CocTagFunc"

local function setup_coc_keymaps()
  local m   = vim.keymap.set
  local exp = { silent=true, noremap=true, expr=true, replace_keycodes=false }
  local function s(extra) return vim.tbl_extend("force", { silent=true, noremap=true }, extra) end

  m("i", "<C-Space>", "coc#refresh()", exp)
  m("i", "<C-@>",    "coc#refresh()", exp)
  m("i", "<TAB>",   [[coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"]], exp)
  m("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], exp)
  m("i", "<CR>",    [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], exp)

  m("n", "[g", "<Plug>(coc-diagnostic-prev)", s{ desc="KEYMAPS: prev diagnostic" })
  m("n", "]g", "<Plug>(coc-diagnostic-next)", s{ desc="KEYMAPS: next diagnostic" })
  m("n", "gl", "<Plug>(coc-diagnostic-info)",  s{ desc="KEYMAPS: diagnostic info float" })

  local function nav(action)
    local ok, jumped = pcall(vim.fn.CocAction, action)
    if ok and jumped then return end
    local word = vim.fn.expand("<cword>")
    if vim.fn.taglist("^"..word.."$")[1] then require("fzf-lua").tags({ search=word })
    else vim.fn.searchdecl(word) end
  end
  m("n", "gd", function() nav("jumpDefinition") end,     s{ desc="KEYMAPS: go to definition" })
  m("n", "gy", function() nav("jumpTypeDefinition") end, s{ desc="KEYMAPS: go to type definition" })
  m("n", "gi", function() nav("jumpImplementation") end, s{ desc="KEYMAPS: go to implementation" })
  m("n", "gr", function() nav("jumpReferences") end,     s{ desc="KEYMAPS: list references" })

  m("n", "K", function()
    if vim.fn.CocAction("hasProvider","hover") then vim.fn.CocActionAsync("doHover")
    else vim.api.nvim_feedkeys("K","in",false) end
  end, s{ desc="KEYMAPS: hover docs" })

  m({"n","v"}, "<leader>ca", "<Plug>(coc-codeaction-selected)", s{ desc="KEYMAPS: code action" })
  m("n",       "<leader>cr", "<Plug>(coc-rename)",              s{ desc="KEYMAPS: rename symbol" })
  m("n",       "<leader>cf", "<Plug>(coc-fix-current)",         s{ desc="KEYMAPS: quickfix current" })
  m({"x","n"}, "<leader>f",  "<Plug>(coc-format-selected)",     { desc="KEYMAPS: format selection" })

  local function fscroll(d)
    if vim.fn["coc#float#has_scroll"]() == 1 then return vim.fn["coc#float#scroll"](d) end
    return d == 1 and "<C-f>" or "<C-b>"
  end
  m({"n","v"}, "<C-f>", function() return fscroll(1) end, { silent=true, nowait=true, expr=true })
  m({"n","v"}, "<C-b>", function() return fscroll(0) end, { silent=true, nowait=true, expr=true })
  m("i", "<C-f>", function()
    return vim.fn["coc#float#has_scroll"]() == 1 and "<c-r>=coc#float#scroll(1)<cr>" or "<Right>"
  end, { silent=true, nowait=true, expr=true })
  m("i", "<C-b>", function()
    return vim.fn["coc#float#has_scroll"]() == 1 and "<c-r>=coc#float#scroll(0)<cr>" or "<Left>"
  end, { silent=true, nowait=true, expr=true })

  m("n", "<leader>da", ":<C-u>CocDiagnostics<CR>",      { silent=true, nowait=true, desc="KEYMAPS: diagnostics float" })
  m("n", "<space>a",   ":<C-u>CocList diagnostics<CR>", { silent=true, nowait=true, desc="KEYMAPS: all diagnostics" })
  m("n", "<space>o",   ":<C-u>CocList outline<CR>",     { silent=true, nowait=true, desc="KEYMAPS: file outline" })
  m("n", "<leader>dd", function() vim.fn.CocAction("diagnosticToggle") end,
    s{ desc="KEYMAPS: toggle diagnostics" })

  vim.api.nvim_create_autocmd("CursorHold", {
    group    = vim.api.nvim_create_augroup("CocHighlight", { clear=true }),
    callback = function() vim.fn.CocActionAsync("highlight") end,
  })
end

if vim.g.coc_service_initialized == 1 then
  setup_coc_keymaps()
else
  vim.api.nvim_create_autocmd("User", {
    pattern="CocNvimInit", once=true, callback=setup_coc_keymaps
  })
end

-- ── GIT ───────────────────────────────────────────────────────────────────────
vim.keymap.set("n", "[d", ":diffget //2<CR>", { silent=true, desc="KEYMAPS: diff get left" })
vim.keymap.set("n", "]d", ":diffget //3<CR>", { silent=true, desc="KEYMAPS: diff get right" })

vim.keymap.set("n", "<leader>gb", function()
  vim.ui.input({ prompt="Compare with (branch/commit/tag, empty=HEAD): " }, function(ref)
    if ref == nil then return end
    vim.cmd("DiffviewOpen" .. (ref ~= "" and (" "..ref) or ""))
  end)
end, { desc="KEYMAPS: git diff vs branch/commit" })

vim.keymap.set("n", "<leader>gh", ":DiffviewFileHistory %<CR>",
  { silent=true, desc="KEYMAPS: git history (current file)" })
vim.keymap.set("n", "<leader>gH", ":DiffviewFileHistory<CR>",
  { silent=true, desc="KEYMAPS: git history (whole repo)" })

vim.keymap.set("n", "<leader>gD", function()
  vim.ui.input({ prompt="Dir A: ", completion="dir" }, function(a)
    if not a or a=="" then return end
    vim.ui.input({ prompt="Dir B: ", completion="dir" }, function(b)
      if not b or b=="" then return end
      vim.cmd("DiffviewOpen --dir-a="..vim.fn.fnameescape(a).." --dir-b="..vim.fn.fnameescape(b))
    end)
  end)
end, { desc="KEYMAPS: diff two directories" })

vim.keymap.set("n", "<leader>gc", ":DiffviewClose<CR>",       { silent=true, desc="KEYMAPS: close diffview" })
vim.keymap.set("n", "<leader>gf", ":DiffviewToggleFiles<CR>", { silent=true, desc="KEYMAPS: toggle diffview panel" })
vim.keymap.set("n", "<leader>gs", ":Git<CR>",                 { silent=true, desc="KEYMAPS: git status (fugitive)" })
vim.keymap.set("n", "<leader>gp", ":Git push<CR>",            { silent=true, desc="KEYMAPS: git push (fugitive)" })
vim.keymap.set("n", "<leader>gl", ":Git log --oneline<CR>",   { silent=true, desc="KEYMAPS: git log (fugitive)" })

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
    vim.notify("Rg: missing pattern", vim.log.levels.WARN)
    return
  end

  local args = {
    "rg",
    "--column", "--line-number", "--no-heading", "--smart-case",
  }
  for _, f in ipairs(extra_flags or {}) do
    table.insert(args, f)
  end
  table.insert(args, "--")
  table.insert(args, pattern)

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if (result.code ~= 0) and (not result.stdout or result.stdout == "") then
        vim.notify("Rg: no results for " .. pattern, vim.log.levels.INFO)
        return
      end
      local lines = vim.split(result.stdout or "", "\n", { trimempty = true })
      vim.fn.setqflist({}, "r", {
        lines = lines,
        title = title or (":Rg " .. pattern),
      })
      vim.cmd("copen | wincmd p")
    end)
  end)
end

vim.api.nvim_create_user_command("Rg", function(opts)
  rg_qf(opts.args, {})
end, { nargs = "+" })

vim.keymap.set("v", "<leader>/", function()
  local saved = vim.fn.getreg("s")
  vim.cmd('noau normal! "sy')
  local sel = vim.fn.getreg("s")
  vim.fn.setreg("s", saved)
  if sel ~= "" then rg_qf(sel, {}) end
end, { desc = "KEYMAPS: search selected text" })

vim.api.nvim_create_user_command("Gr", function(opts)
  vim.fn.setqflist({}, "r", {
    lines = vim.fn.systemlist("grep -rnI " .. vim.fn.shellescape(opts.args)),
  })
  vim.cmd("copen")
end, { nargs = "?" })

vim.cmd("cabbrev rg Rg")
vim.cmd("cabbrev gr Gr")

vim.api.nvim_create_user_command("RmTrailing", function(opts)
  vim.cmd(string.format("%s,%ss/\\s\\+$//e", opts.line1, opts.line2))
end, { range = "%" })
vim.cmd("cabbrev rmtrailing RmTrailing")

-- ── KEYMAPS ───────────────────────────────────────────────────────────────────
vim.keymap.set("n", "Q", "<Nop>")
vim.keymap.set("n", "<leader>yf", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end,
  { desc="KEYMAPS: yank file path" })
vim.keymap.set("n", "<C-N>", function() require("oil").toggle_float() end,
  { silent=true, desc="KEYMAPS: toggle explorer (oil)" })
vim.keymap.set("n", "=j", ":%!python3 -m json.tool<CR>", { desc="KEYMAPS: format JSON" })

-- ── WORKFLOW KEYMAPS ─────────────────────────────────────────────────────────
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>",  { desc="KEYMAPS: save file" })
vim.keymap.set("n", "<leader>x", "<cmd>bw<CR>", { desc="KEYMAPS: close buffer" })

vim.keymap.set("n", "<leader>v", "<cmd>vsplit<CR>", { desc="KEYMAPS: vertical split" })
vim.keymap.set("n", "<leader>s", "<cmd>split<CR>",  { desc="KEYMAPS: horizontal split" })

vim.keymap.set("n", "<M-Up>",    "<cmd>resize +2<CR>",          { desc="KEYMAPS: resize ↑" })
vim.keymap.set("n", "<M-Down>",  "<cmd>resize -2<CR>",          { desc="KEYMAPS: resize ↓" })
vim.keymap.set("n", "<M-Left>",  "<cmd>vertical resize -2<CR>", { desc="KEYMAPS: resize ←" })
vim.keymap.set("n", "<M-Right>", "<cmd>vertical resize +2<CR>", { desc="KEYMAPS: resize →" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc="KEYMAPS: move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc="KEYMAPS: move selection up" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc="KEYMAPS: scroll down (centred)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc="KEYMAPS: scroll up (centred)" })
vim.keymap.set("n", "n",     "nzzzv",   { desc="KEYMAPS: next search (centred)" })
vim.keymap.set("n", "N",     "Nzzzv",   { desc="KEYMAPS: prev search (centred)" })

vim.api.nvim_set_keymap("i", "<leader>now",
  "<C-R>=strftime('%Y-%m-%d %H:%M')<CR>",
  { noremap = true, desc = "Insert current datetime" }
)

-- ── RELATIVE NUMBER TOGGLE ────────────────────────────────────────────────────
local rnu = vim.api.nvim_create_augroup("RelNum", { clear=true })
vim.api.nvim_create_autocmd({"BufEnter","FocusGained","InsertLeave","WinEnter"}, { group=rnu,
  callback=function() if vim.wo.number and vim.fn.mode()~="i" then vim.wo.relativenumber=true end end })
vim.api.nvim_create_autocmd({"BufLeave","FocusLost","InsertEnter","WinLeave"}, { group=rnu,
  callback=function() if vim.wo.number then vim.wo.relativenumber=false end end })

-- ── TREESITTER HIGHLIGHT + FOLD ───────────────────────────────────────────────
-- NOTE: In 0.12, vim.treesitter.get_parser() returns nil on failure instead of
-- throwing, so pcall is no longer needed — but kept for safety during transition.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("TSHighlightFold", { clear=true }),
  callback = function(ev)
    local buf  = ev.buf
    local name = vim.fn.fnamemodify(ev.file, ":t")
    local is_fugitive = ev.file:match("^fugitive://") ~= nil
    local bt  = vim.bo[buf].buftype
    local win = vim.fn.bufwinid(buf)
    local in_diff_win = bt == "nofile" and win ~= -1 and vim.wo[win].diff
    if is_fugitive or in_diff_win then
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.foldlevel  = 20
      return
    end

    local has_parser = false
    if vim.api.nvim_buf_line_count(buf) <= 10000 then
      -- 0.12: get_parser returns nil on failure, no throw
      local parser = vim.treesitter.get_parser(buf)
      if parser then
        has_parser = true
        vim.treesitter.stop(buf)
        vim.treesitter.start(buf)
      end
    end

    if name:match("%.properties$") or name:match("%.log$") then
      vim.opt_local.foldmethod = "manual"
      return
    end

    if has_parser then
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        local w = vim.fn.bufwinid(buf)
        if w == -1 then return end
        if vim.wo[w].diff then
          vim.wo[w].foldmethod = "manual"
          vim.wo[w].foldlevel  = 20
          return
        end
        vim.wo[w].foldmethod = "expr"
        vim.wo[w].foldexpr   = "v:lua.vim.treesitter.foldexpr()"
      end)
    else
      vim.opt_local.foldmethod = "indent"
    end
  end,
})

-- ── CASCADING .exrc LOADER ────────────────────────────────────────────────────
local _exrc_sourced = {}
vim.api.nvim_create_autocmd("BufEnter", {
  group    = vim.api.nvim_create_augroup("ExrcLoader", { clear=true }),
  callback = function()
    local dir = vim.fn.expand("%:p:h")
    if dir == "" then return end
    local dirs, prev, cur = {}, "", dir
    while cur ~= prev do
      table.insert(dirs, 1, cur); prev=cur; cur=vim.fn.fnamemodify(cur,":h")
    end
    for _, d in ipairs(dirs) do
      local f = d.."/.exrc"
      if not _exrc_sourced[f] and vim.fn.filereadable(f)==1 then
        _exrc_sourced[f] = true
        vim.cmd("sandbox source "..vim.fn.fnameescape(f))
      end
    end
  end,
})

-- ── LANGUAGE SETTINGS ─────────────────────────────────────────────────────────
local languages = {
  { pattern = { "c", "cpp" }, tabs = { size=4, expand=false },
    rg_flags = { "--type", "c", "--type", "cpp",
                 "-g", "!thrift", "-g", "!thriftzg" } },
  { pattern = "java", tabs = { size=2, expand=false },
    rg_flags = { "--type", "java",
                 "-g", "!thrift", "-g", "!thriftzg" } },
  { pattern = "rust",               tabs = { size=2, expand=false } },
  { pattern = "go",                 tabs = { size=4, expand=false } },
  { pattern = "python",             tabs = { size=4, expand=true  } },
  { pattern = "sh",                 tabs = { size=2, expand=true  } },
  { pattern = { "lua", "vim" },     tabs = { size=2, expand=true  } },
  { pattern = "tla",                tabs = { size=2, expand=true  } },
}

local function apply_language(lang)
  if lang.tabs then
    local t = lang.tabs
    vim.bo.tabstop     = t.size
    vim.bo.softtabstop = t.size
    vim.bo.shiftwidth  = t.size
    vim.bo.expandtab   = t.expand
  end

  if lang.rg_flags then
    local ft_label = type(lang.pattern) == "table"
      and table.concat(lang.pattern, "/")
      or  lang.pattern

    vim.api.nvim_buf_create_user_command(0, "Rg", function(opts)
      rg_qf(
        opts.args,
        lang.rg_flags,
        (":Rg(%s) %s"):format(ft_label, opts.args)
      )
    end, { nargs = "+", desc = "Rg scoped to " .. ft_label })
  end
end

for _, lang in ipairs(languages) do
  vim.api.nvim_create_autocmd("FileType", {
    pattern  = lang.pattern,
    callback = function() apply_language(lang) end,
  })
end

vim.api.nvim_create_autocmd({"BufNewFile","BufReadPost"}, {
  pattern="*.py2", callback=function() vim.bo.filetype="python" end
})
vim.api.nvim_create_autocmd({"BufNewFile","BufReadPost"}, {
  pattern="*.tla", callback=function() vim.bo.filetype="tla" end
})

-- ── SNIPPETS / TEMPLATES ─────────────────────────────────────────────────────
local function snip_dir()
  if vim.env.APPDIR then
    local p = vim.env.APPDIR .. "/usr/share/nvim/snippets"
    if vim.fn.isdirectory(p) == 1 then return p end
  end
  return vim.fn.fnamemodify(vim.fn.resolve(vim.env.MYVIMRC or
    (vim.fn.stdpath("config").."/init.lua")), ":h") .. "/snippets"
end

vim.api.nvim_create_autocmd("VimEnter", { once=true, callback=function()
  local name  = vim.trim(vim.fn.system("git config user.name"))
  local email = vim.trim(vim.fn.system("git config user.email"))
  vim.g.code_author = name .. " (" .. email .. ")"
end })

local function apply_template(path)
  if vim.fn.filereadable(path) == 0 then
    vim.notify("Template not found: " .. path, vim.log.levels.WARN); return
  end
  local out, cursor = {}, {0,0}
  local classname = vim.fn.expand("%:t:r"):gsub("^%l", string.upper)
  for row, line in ipairs(vim.fn.readfile(path)) do
    line = line:gsub("{{FILE}}",   vim.fn.expand("%:t"))
                :gsub("{{AUTHOR}}", vim.g.code_author or "")
                :gsub("{{DATE}}",   vim.fn.strftime("%B %d, %Y, %I:%M %p"))
                :gsub("{{CLASS}}",  classname)
    local ci = line:find("{{CURSOR}}")
    if ci then cursor={row,ci}; line=line:gsub("{{CURSOR}}","") end
    table.insert(out, line)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
  if cursor[1] ~= 0 then vim.fn.cursor(cursor[1], cursor[2]) end
end

vim.api.nvim_create_user_command("Snipcode", function(opts)
  local ft = opts.args ~= "" and vim.trim(opts.args)
          or (vim.bo.filetype ~= "" and vim.bo.filetype or vim.fn.expand("%:e"))
  if ft == "" then
    vim.notify("Snipcode: cannot determine file type. Pass it explicitly: :Snipcode <type>",
      vim.log.levels.WARN); return
  end
  apply_template(snip_dir() .. "/template." .. ft)
end, { nargs="?" })

vim.api.nvim_create_user_command("Snipmake", function(opts)
  local ft   = opts.args ~= "" and vim.trim(opts.args) or (vim.bo.filetype or "")
  local sdir = snip_dir()
  local tpl  = ft ~= "" and (sdir .. "/" .. ft .. ".make") or ""
  if tpl == "" or vim.fn.filereadable(tpl) == 0 then tpl = sdir .. "/default.make" end
  if vim.fn.filereadable(tpl) == 0 then
    vim.notify("Snipmake: no template found in " .. sdir, vim.log.levels.ERROR); return
  end
  local abs = vim.fn.getcwd() .. "/Makefile"
  if vim.fn.filereadable(abs) == 1 then
    vim.ui.input({ prompt="Makefile exists. Overwrite? [y/N] " }, function(answer)
      if answer == nil or answer:lower() ~= "y" then
        vim.notify("Snipmake: aborted.", vim.log.levels.INFO); return
      end
      vim.fn.writefile(vim.fn.readfile(tpl), abs)
      vim.notify("Snipmake: written from " .. tpl, vim.log.levels.INFO)
    end)
  else
    vim.fn.writefile(vim.fn.readfile(tpl), abs)
    vim.notify("Snipmake: written from " .. tpl, vim.log.levels.INFO)
  end
end, { nargs="?" })
