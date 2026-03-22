-- ~/.config/nvim/init.lua  (also embedded in AppImage at $APPDIR/nvim/init.lua)

-- ── LEADER ───────────────────────────────────────────────────────────────────
vim.g.mapleader = ","

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
o.history       = 50
o.hlsearch      = true; o.incsearch = true; o.ignorecase = true; o.smartcase = true
o.mouse         = "a"
o.textwidth     = 0
o.splitbelow    = true; o.splitright = true
-- Global fold default: indent (always safe). Per-buffer autocmd upgrades to
-- treesitter expr once a parser is confirmed active, avoiding E350.
o.foldmethod    = "indent"
o.foldlevel     = 20
o.diffopt:append("followwrap,algorithm:histogram,indent-heuristic")
o.autoread      = true; o.autowrite = true
o.showcmd       = true; o.ruler = true
o.timeout       = true; o.timeoutlen = 1200
o.visualbell    = true; o.errorbells = false
o.display       = "lastline,uhex"; o.colorcolumn = "80"
o.switchbuf     = "useopen,usetab"
o.backup        = false; o.writebackup = false
o.updatetime    = 300; o.signcolumn = "yes"
o.background    = "dark"
-- 24-bit colour. tmux also needs:
--   set-option -a terminal-features 'screen-256color:RGB'
--   set-option -g focus-events on
o.termguicolors = true
o.secure        = true

o.list = true
o.listchars = {
  eol="¬", trail="·", nbsp="◇", tab="→ ",
  extends="▸", precedes="◂", multispace="···⬝", leadmultispace="│   ",
}
vim.api.nvim_create_autocmd("ColorScheme", { callback = function()
  for _, g in ipairs({ "Whitespace", "NonText", "SpecialKey" }) do
    vim.api.nvim_set_hl(0, g, { fg="#545c7e", ctermfg=60, bg="none" })
  end
end })

vim.g.netrw_list_hide   = ".*\\.swp$,.*\\.pyc,ENV,.git/,.*\\.map,.*\\.plist$"
vim.g.netrw_bufsettings = "noma nomod nu nobl nowrap ro"
vim.g.netrw_winsize     = 20

-- ── CLIPBOARD ────────────────────────────────────────────────────────────────
do
  local has_provider = (
    vim.fn.executable("xclip")    == 1 or
    vim.fn.executable("xsel")     == 1 or
    vim.fn.executable("wl-copy")  == 1 or
    vim.fn.executable("pbcopy")   == 1 or
    vim.fn.executable("win32yank") == 1
  )
  if has_provider then
    o.clipboard = "unnamedplus"
  else
    vim.notify(
      "[clipboard] No provider found (xclip/xsel/wl-copy/pbcopy). " ..
      "Clipboard sync disabled. Install one to enable it.",
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

-- Treesitter: nvim-treesitter kept for its queries/ dir and textobjects.
-- Highlight driven by nvim 0.11's native vim.treesitter.start() from BufReadPost.
local _ts_cfg = {
  ensure_installed = { "c","cpp","java","go","rust","python",
                       "lua","bash","json","yaml","toml","cmake",
                       "tlaplus" },
  auto_install  = false,
  sync_install  = false,
  highlight = { enable = false },  -- driven by BufReadPost autocmd (TSHighlightFold)
  indent = { enable = true },
  textobjects = {
    select = {
      enable = true, lookahead = true,
      keymaps = {
        ["af"] = { query="@function.outer", desc="KEYMAPS: around function" },
        ["if"] = { query="@function.inner", desc="KEYMAPS: inner function" },
        ["ac"] = { query="@class.outer",    desc="KEYMAPS: around class" },
        ["ic"] = { query="@class.inner",    desc="KEYMAPS: inner class" },
        ["aa"] = { query="@parameter.outer",desc="KEYMAPS: around argument" },
        ["ia"] = { query="@parameter.inner",desc="KEYMAPS: inner argument" },
        ["ab"] = { query="@block.outer",    desc="KEYMAPS: around block" },
        ["ib"] = { query="@block.inner",    desc="KEYMAPS: inner block" },
      },
    },
    move = {
      enable = true, set_jumps = true,
      -- NOTE: ]f/[f = jump between functions; ]F/[F = function end.
      -- ]c/[c are reserved for DiffView diff chunk navigation (see GIT section).
      goto_next_start     = { ["]f"]={ query="@function.outer", desc="KEYMAPS: next function start" } },
      goto_next_end       = { ["]F"]={ query="@function.outer", desc="KEYMAPS: next function end" } },
      goto_previous_start = { ["[f"]={ query="@function.outer", desc="KEYMAPS: prev function start" } },
      goto_previous_end   = { ["[F"]={ query="@function.outer", desc="KEYMAPS: prev function end" } },
      -- Class navigation kept on ]C/[C to free ]c/[c for diffview
      goto_next_end       = { ["]C"]={ query="@class.outer",    desc="KEYMAPS: next class end" } },
      goto_previous_end   = { ["[C"]={ query="@class.outer",    desc="KEYMAPS: prev class end" } },
    },
    swap = {
      enable        = true,
      swap_next     = { ["<leader>sn"]={ query="@parameter.inner", desc="KEYMAPS: swap arg →" } },
      swap_previous = { ["<leader>sp"]={ query="@parameter.inner", desc="KEYMAPS: swap arg ←" } },
    },
  },
}

require("lazy").setup({

  { "folke/tokyonight.nvim", lazy=false, priority=1000,
    opts = { style="moon", transparent=true,
             styles = { sidebars="transparent", floats="transparent" } },
  },

  { "neoclide/coc.nvim", branch="release", event="BufReadPre" },

  { "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate", lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    config = function()
      local ok, cfg = pcall(require, "nvim-treesitter.configs")
      if not ok then return end
      cfg.setup(_ts_cfg)
    end,
  },
  { "nvim-treesitter/nvim-treesitter-textobjects", lazy=true },

  -- ── GIT ──────────────────────────────────────────────────────────────────
  -- Unified ]h / [h design:
  --   • In a normal tracked buffer  → gitsigns next/prev hunk
  --   • In a DiffView diff panel    → DiffView next/prev diff chunk
  --
  -- Key safety rules enforced here:
  --   1. gitsigns on_attach SKIPS diffview buffers (buftype=nofile, diff=true)
  --      so it never installs competing buffer-local maps there.
  --   2. DiffView installs its OWN buffer-local ]h/[h via its keymaps config,
  --      so the mapping is set only after diffview's own attach — no race.
  --   3. The gitsigns keymap callbacks guard against a nil gitsigns module
  --      (lazy-load timing) by reading from package.loaded at call time,
  --      not at on_attach time.
  --   4. DiffView action calls are wrapped in pcall so a lazy-load miss
  --      (e.g. pressing ]h before diffview fully initialises) fails silently.
  --   5. No global ]h/[h mapping exists — both are buffer-local only.
  --      This means there is zero risk of one context's mapping bleeding
  --      into the other.

  { "lewis6991/gitsigns.nvim", event="BufReadPre",
    opts = {
      signs = { add={text="+"}, change={text="~"}, delete={text="_"},
                topdelete={text="‾"}, changedelete={text="~"} },
      on_attach = function(buf)
        -- ── Guard 1: never attach to DiffView's synthetic diff buffers.
        -- DiffView diff panels are nofile buffers with vim's diff mode active.
        -- Checking both conditions avoids false positives (e.g. a real file
        -- opened in vimdiff manually still gets gitsigns correctly).
        local ft = vim.bo[buf].filetype
        local bt = vim.bo[buf].buftype
        local in_diffview = (bt == "nofile") and (
          ft == "DiffviewFiles" or
          ft == "DiffviewFileHistory" or
          ft:match("^Diffview")  -- forward-compat: any new diffview filetype
        )
        -- Also skip if the buffer is a diff panel set up by diffview
        -- (diffview sets b:diffview_view_initialized on its panels)
        local is_dv_panel = vim.b[buf].diffview_view_initialized ~= nil

        if in_diffview or is_dv_panel then return end

        -- ── Guard 2: read gitsigns from package.loaded at *call time*,
        -- not at on_attach time, to survive lazy-load ordering.
        local function gs()
          return package.loaded.gitsigns
        end

        local m = function(k, f, d)
          vim.keymap.set("n", k, f, { buffer=buf, silent=true, desc=d })
        end

        -- ]h / [h — hunk navigation in normal tracked files
        m("]h", function()
          local g = gs(); if g then g.next_hunk() end
        end, "KEYMAPS: next git hunk")
        m("[h", function()
          local g = gs(); if g then g.prev_hunk() end
        end, "KEYMAPS: prev git hunk")

        m("<leader>hp", function()
          local g = gs(); if g then g.preview_hunk() end
        end, "KEYMAPS: preview hunk inline")
        m("<leader>hs", function()
          local g = gs(); if g then g.stage_hunk() end
        end, "KEYMAPS: stage hunk")
        m("<leader>hS", function()
          local g = gs(); if g then g.stage_buffer() end
        end, "KEYMAPS: stage entire buffer")
        m("<leader>hu", function()
          local g = gs(); if g then g.reset_hunk() end
        end, "KEYMAPS: undo/reset hunk")
        m("<leader>hb", function()
          local g = gs(); if g then g.blame_line({ full=true }) end
        end, "KEYMAPS: blame line")
      end,
    },
  },

  -- fugitive: commit, push, log, blame, interactive index editing.
  -- Keymaps defined below in the GIT section.
  { "tpope/vim-fugitive",
    cmd = { "Git","Gedit","Gdiffsplit","Gread","Gwrite","GBrowse" },
  },

  -- diffview: side-by-side diff, file history, directory compare.
  --
  -- ]h / [h are mapped here as buffer-local keys on DiffView's own panels,
  -- mirroring the gitsigns convention so muscle memory works everywhere.
  -- They call diffview's select_next/prev_entry in the file panel and
  -- ]c / [c (next/prev diff hunk) in diff view panels.
  --
  -- Implementation note: diffview's `keymaps` table entries are set by
  -- diffview itself via its BufEnter/attach logic — they are always
  -- buffer-local and always installed AFTER gitsigns on_attach has already
  -- been skipped (Guard 1 above), so there is no race between them.
  { "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen","DiffviewFileHistory","DiffviewClose","DiffviewToggleFiles" },
    opts = function()
      -- We build opts as a function so we can safely require("diffview.actions")
      -- only after the plugin is loaded (lazy guarantee inside opts-function).
      local actions = require("diffview.actions")
      return {
        keymaps = {
          -- diff view panels (the actual side-by-side file content windows)
          view = {
            -- ]h / [h  →  next/prev diff chunk (mirrors gitsigns in normal bufs)
            { "n", "]h", actions.next_conflict or actions.select_next_entry,
              { desc="KEYMAPS: diffview next diff chunk" } },
            { "n", "[h", actions.prev_conflict or actions.select_prev_entry,
              { desc="KEYMAPS: diffview prev diff chunk" } },
            -- keep ]c/[c as well (diffview's own default) — removing them
            -- would break users who learnt the default mapping
            { "n", "]c", actions.next_conflict or actions.select_next_entry,
              { desc="KEYMAPS: diffview next diff chunk (alt)" } },
            { "n", "[c", actions.prev_conflict or actions.select_prev_entry,
              { desc="KEYMAPS: diffview prev diff chunk (alt)" } },
            { "n", "q",  "<cmd>DiffviewClose<CR>",
              { desc="KEYMAPS: close diffview" } },
            { "n", "<leader>hs", actions.stage_all,
              { desc="KEYMAPS: stage file in diffview" } },
          },
          -- file panel (left-hand file list)
          file_panel = {
            -- ]h / [h  →  move between files in the list
            { "n", "]h", actions.select_next_entry,
              { desc="KEYMAPS: diffview next file" } },
            { "n", "[h", actions.select_prev_entry,
              { desc="KEYMAPS: diffview prev file" } },
            { "n", "s",  actions.toggle_stage_entry,
              { desc="KEYMAPS: stage/unstage file" } },
            { "n", "q",  "<cmd>DiffviewClose<CR>",
              { desc="KEYMAPS: close diffview" } },
          },
          -- file history panel
          file_history_panel = {
            { "n", "]h", actions.select_next_entry,
              { desc="KEYMAPS: diffview next entry" } },
            { "n", "[h", actions.select_prev_entry,
              { desc="KEYMAPS: diffview prev entry" } },
            { "n", "q",  "<cmd>DiffviewClose<CR>",
              { desc="KEYMAPS: close diffview" } },
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

  { "nvim-lualine/lualine.nvim", event="VeryLazy",
    opts = {
      options = { theme="tokyonight", globalstatus=true,
                  component_separators={left="",right=""},
                  section_separators={left="",right=""} },
      sections = {
        lualine_a = { { "mode", fmt=function(s) return s:sub(1,1) end } },
        lualine_b = { "branch","diff","diagnostics" },
        lualine_c = { {"filename",path=1},
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
      { "<leader>r", function() require("fzf-lua").oldfiles() end,                                desc="KEYMAPS: recent files" },  -- ← ADD THIS
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
  performance = { rtp = { disabled_plugins = { "gzip","tarPlugin","tohtml","tutor","zipPlugin" } } },
})

-- After lazy.setup(), re-run highlight for any buffer already loaded:
vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_exec_autocmds("BufReadPost", { buffer = buf })
    end
  end
end })

-- ── COLORSCHEME ───────────────────────────────────────────────────────────────
vim.cmd.colorscheme("tokyonight-moon")
for _, g in ipairs({ "Normal","NormalNC","LineNr","SignColumn","StatusLine" }) do
  vim.api.nvim_set_hl(0, g, { bg="none", ctermbg="none" })
end

if (vim.env.TERM or ""):match("^screen") then
  vim.keymap.set({"n","v"}, "~", "<Nop>")
end

-- ── COC.NVIM ──────────────────────────────────────────────────────────────────
vim.o.tagfunc = "CocTagFunc"  -- C-] → coc first, ctags fallback

vim.api.nvim_create_autocmd("User", { pattern="CocNvimInit", once=true, callback=function()
  local m   = vim.keymap.set
  local exp = { silent=true, noremap=true, expr=true, replace_keycodes=false }
  local function s(extra) return vim.tbl_extend("force", { silent=true, noremap=true }, extra) end

  m("i", "<TAB>", function()
    if vim.fn["coc#pum#visible"]() == 1 then return vim.fn["coc#pum#next"](1) end
    local col = vim.fn.col(".") - 1
    if col == 0 or vim.fn.getline("."):sub(col,col):match("%s") then return "<Tab>" end
    return vim.fn["coc#refresh"]()
  end, { silent=true, expr=true })
  m("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], exp)
  m("i", "<CR>",    [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], exp)
  m("i", "<C-@>",   "coc#refresh()", exp)

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

  m("n", "<leader>da", ":<C-u>CocDiagnostics<CR>",      { silent=true, nowait=true, desc="KEYMAPS: diagnostics (buffer float)" })
  m("n", "<space>a",   ":<C-u>CocList diagnostics<CR>", { silent=true, nowait=true, desc="KEYMAPS: all diagnostics (CocList)" })
  m("n", "<space>o",   ":<C-u>CocList outline<CR>",     { silent=true, nowait=true, desc="KEYMAPS: file outline" })
  m("n", "<leader>dd", function() vim.fn.CocAction("diagnosticToggle") end,
    s{ desc="KEYMAPS: toggle diagnostics" })

  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function() vim.fn.CocActionAsync("highlight") end
  })
end })

-- ── GIT ───────────────────────────────────────────────────────────────────────
-- Keymap overview:
--   [d / ]d    — diff get left/right in 3-way merge (fugitive Gdiffsplit)
--   ]h / [h    — gitsigns: next/prev hunk while editing a normal buffer
--   ]c / [c    — diffview built-in: next/prev diff chunk inside diffview panels
--   <leader>gb — open DiffviewOpen vs branch/commit (prompts for ref)
--   <leader>gh — DiffviewFileHistory current file
--   <leader>gH — DiffviewFileHistory whole repo
--   <leader>gD — diff two arbitrary directories
--   <leader>gc — close diffview
--   <leader>gf — toggle diffview file panel
--   <leader>gs — :Git (fugitive status — use for staging, commit, push)
--   <leader>gp — :Git push
--   <leader>gl — :Git log --oneline

vim.keymap.set("n", "[d", ":diffget //2<CR>", { silent=true, desc="KEYMAPS: diff get left" })
vim.keymap.set("n", "]d", ":diffget //3<CR>", { silent=true, desc="KEYMAPS: diff get right" })

-- Diffview: compare, history, directory diff
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

vim.keymap.set("n", "<leader>gc", ":DiffviewClose<CR>",
  { silent=true, desc="KEYMAPS: close diffview" })
vim.keymap.set("n", "<leader>gf", ":DiffviewToggleFiles<CR>",
  { silent=true, desc="KEYMAPS: toggle diffview file panel" })

-- Fugitive: index/stage/commit/push workflow
vim.keymap.set("n", "<leader>gs", ":Git<CR>",
  { silent=true, desc="KEYMAPS: git status (fugitive)" })
vim.keymap.set("n", "<leader>gp", ":Git push<CR>",
  { silent=true, desc="KEYMAPS: git push (fugitive)" })
vim.keymap.set("n", "<leader>gl", ":Git log --oneline<CR>",
  { silent=true, desc="KEYMAPS: git log (fugitive)" })

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

local function rg_qf(pattern, rg_extra, title)
  if pattern == "" then vim.notify("Rg: missing pattern", vim.log.levels.WARN); return end
  local lines = vim.fn.systemlist(
    "rg --column --line-number --no-heading --smart-case " ..
    (rg_extra or "") .. " " .. vim.fn.shellescape(pattern))
  vim.fn.setqflist({}, "r", { lines=lines, title=title or (":Rg "..pattern) })
  if #vim.fn.getqflist() == 0 then vim.notify("Rg: no results for "..pattern); return end
  vim.cmd("copen | wincmd p")
end

vim.api.nvim_create_user_command("Rg",     function(o) rg_qf(o.args) end, { nargs="+" })
vim.api.nvim_create_user_command("RgLive", function(o) require("fzf-lua").live_grep({ search=o.args }) end, { nargs="*" })
vim.api.nvim_create_user_command("Gr", function(o)
  vim.fn.setqflist({}, "r", { lines=vim.fn.systemlist("grep -rnI "..vim.fn.shellescape(o.args)) })
  vim.cmd("copen")
end, { nargs="?" })
vim.cmd("cabbrev rg Rg | cabbrev gr Gr")

-- ── MISC KEYMAPS ──────────────────────────────────────────────────────────────
vim.keymap.set("n", "Q", "<Nop>")
vim.keymap.set("n", "<leader>yf", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end,
  { desc="KEYMAPS: yank file path" })
vim.keymap.set("n", "<C-N>", ":Lexplore<CR>",               { silent=true, desc="KEYMAPS: toggle explorer" })
vim.keymap.set("n", "=j",    ":%!python3 -m json.tool<CR>", { desc="KEYMAPS: format JSON" })
vim.cmd("cabbrev now put =strftime('%Y-%m-%d %H:%M')")

-- ── RELATIVE NUMBER TOGGLE ────────────────────────────────────────────────────
local rnu = vim.api.nvim_create_augroup("RelNum", { clear=true })
vim.api.nvim_create_autocmd({"BufEnter","FocusGained","InsertLeave","WinEnter"}, { group=rnu,
  callback=function() if vim.wo.number and vim.fn.mode()~="i" then vim.wo.relativenumber=true end end })
vim.api.nvim_create_autocmd({"BufLeave","FocusLost","InsertEnter","WinLeave"}, { group=rnu,
  callback=function() if vim.wo.number then vim.wo.relativenumber=false end end })

-- ── TREESITTER HIGHLIGHT + FOLD (per-buffer, after lazy.setup) ──────────────
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("TSHighlightFold", { clear = true }),
  callback = function(ev)
    local buf  = ev.buf
    local name = vim.fn.fnamemodify(ev.file, ":t")

    -- highlight
    if vim.api.nvim_buf_line_count(buf) <= 10000
        and pcall(vim.treesitter.get_parser, buf) then
      vim.treesitter.stop(buf)
      vim.treesitter.start(buf)
    end

    -- fold
    if name:match("%.properties$") or name:match("%.log$") then
      vim.opt_local.foldmethod = "manual"
      return
    end
    local has_parser = pcall(vim.treesitter.get_parser, buf)
    if has_parser then
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        local win = vim.fn.bufwinid(buf)
        if win == -1 then return end
        vim.wo[win].foldmethod = "expr"
        vim.wo[win].foldexpr   = "v:lua.vim.treesitter.foldexpr()"
      end)
    else
      vim.opt_local.foldmethod = "indent"
    end
  end,
})

-- ── CASCADING .exrc LOADER ────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("BufEnter", { callback=function()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then return end
  local dirs, prev, cur = {}, "", dir
  while cur ~= prev do
    table.insert(dirs, 1, cur); prev=cur; cur=vim.fn.fnamemodify(cur,":h")
  end
  for _, d in ipairs(dirs) do
    local f = d.."/.exrc"
    if vim.fn.filereadable(f)==1 then vim.cmd("sandbox source "..vim.fn.fnameescape(f)) end
  end
end })

-- ── LANGUAGE SETTINGS ─────────────────────────────────────────────────────────
-- To add a language: add one block.
-- rg_types: ripgrep --type flags for scoped :Rg in that filetype.
local languages = {
  {
    pattern  = {"c","cpp"},
    tabs     = { size=4, expand=false },
    rg_types = "--type c --type cpp -g '!thift' -g '!thiftzg'",
  },
  {
    pattern  = "java",
    tabs     = { size=2, expand=false },
  },
  {
    pattern  = "rust",
    tabs     = { size=2, expand=false },
  },
  {
    pattern  = "go",
    tabs     = { size=4, expand=false },
  },
  {
    pattern  = "python",
    tabs     = { size=4, expand=true },
  },
  {
    pattern  = "sh",
    tabs     = { size=2, expand=true },
  },
  {
    pattern  = {"lua","vim"},
    tabs     = { size=2, expand=true },
  },
  {
    pattern  = "tla",
    tabs     = { size=2, expand=true },
  },
}

local function apply_language(lang)
  if lang.tabs then
    local t = lang.tabs
    vim.bo.tabstop = t.size; vim.bo.softtabstop = t.size; vim.bo.shiftwidth = t.size
    vim.bo.expandtab = t.expand
  end
  if lang.rg_types then
    vim.api.nvim_buf_create_user_command(0, "Rg", function(o)
      rg_qf(o.args, lang.rg_types, ":Rg("..table.concat(
        type(lang.pattern)=="table" and lang.pattern or {lang.pattern}, "/")..") "..o.args)
    end, { nargs="+" })
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
-- Snippets dir = same folder as this init.lua (AppImage-aware).
local function snip_dir()
  if vim.env.APPDIR then
    local p = vim.env.APPDIR .. "/usr/share/nvim/snippets"
    if vim.fn.isdirectory(p) == 1 then return p end
  end
  return vim.fn.fnamemodify(vim.fn.resolve(vim.env.MYVIMRC or
    (vim.fn.stdpath("config").."/init.lua")), ":h") .. "/snippets"
end

local function has_makefile()
  return vim.fn.filereadable("Makefile")==1 or vim.fn.filereadable("makefile")==1
end

-- :Snipcode [<file_type>]
--     Load a code template for the current file type (or explicit <file_type>).
--     Template file: snippets/template.<file_type>
--     Placeholders: {{FILE}}, {{AUTHOR}}, {{DATE}}, {{CURSOR}}, {{CLASS}} (java)
--
-- :Snipmake [<file_type>]
--     Create a Makefile in cwd using snippets/<file_type>.make (or default.make).
--     Prompts for confirmation if Makefile already exists.
--     All generated Makefiles support: make run [in=file] [out=file] [err=file]

do
  local name  = vim.trim(vim.fn.system("git config user.name"))
  local email = vim.trim(vim.fn.system("git config user.email"))
  vim.g.code_author = name .. " (" .. email .. ")"
end

local function apply_template(path)
  if vim.fn.filereadable(path) == 0 then
    vim.notify("Template not found: " .. path, vim.log.levels.WARN); return
  end
  local out, cursor = {}, {0,0}
  -- Derive class name from filename (used in Java template)
  local classname = vim.fn.expand("%:t:r")
  classname = classname:gsub("^%l", string.upper)  -- capitalize first letter

  for row, line in ipairs(vim.fn.readfile(path)) do
    line = line:gsub("{{FILE}}",   vim.fn.expand("%:t"))
                :gsub("{{AUTHOR}}", vim.g.code_author)
                :gsub("{{DATE}}",   vim.fn.strftime("%B %d, %Y, %I:%M %p"))
                :gsub("{{CLASS}}",  classname)
    local ci = line:find("{{CURSOR}}")
    if ci then cursor={row,ci}; line=line:gsub("{{CURSOR}}","") end
    table.insert(out, line)
  end
  -- Remove trailing empty line added by append(0, ...) sentinel
  vim.fn.append(0, out)
  if cursor[1] ~= 0 then vim.fn.cursor(cursor[1], cursor[2]) end
end

vim.api.nvim_create_user_command("Snipcode", function(opts)
  local ft = opts.args ~= "" and vim.trim(opts.args)
          or (vim.bo.filetype ~= "" and vim.bo.filetype or vim.fn.expand("%:e"))
  if ft == "" then
    vim.notify("Snipcode: cannot determine file type. Pass it explicitly: :Snipcode <type>",
      vim.log.levels.WARN); return
  end
  local path = snip_dir() .. "/template." .. ft
  apply_template(path)
end, { nargs="?" })

vim.api.nvim_create_user_command("Snipmake", function(opts)
  local ft = opts.args ~= "" and vim.trim(opts.args)
          or (vim.bo.filetype ~= "" and vim.bo.filetype or "")
  local sdir = snip_dir()
  local tpl  = ft ~= "" and (sdir .. "/" .. ft .. ".make") or ""
  if tpl == "" or vim.fn.filereadable(tpl) == 0 then
    tpl = sdir .. "/default.make"
  end
  if vim.fn.filereadable(tpl) == 0 then
    vim.notify("Snipmake: no template found in " .. sdir, vim.log.levels.ERROR); return
  end

  local abs = vim.fn.getcwd() .. "/Makefile"
  if vim.fn.filereadable(abs) == 1 then
    vim.ui.input({ prompt="Makefile already exists at " .. abs .. ". Overwrite? [y/N] " },
      function(answer)
        if answer == nil or answer:lower() ~= "y" then
          vim.notify("Snipmake: aborted.", vim.log.levels.INFO); return
        end
        vim.fn.writefile(vim.fn.readfile(tpl), abs)
        vim.notify("Snipmake: created Makefile from " .. tpl, vim.log.levels.INFO)
      end)
  else
    vim.fn.writefile(vim.fn.readfile(tpl), abs)
    vim.notify("Snipmake: created Makefile from " .. tpl, vim.log.levels.INFO)
  end
end, { nargs="?" })

