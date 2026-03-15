-- ~/.config/nvim/init.lua  (also embedded in AppImage at $APPDIR/nvim/init.lua)

-- ── LEADER ───────────────────────────────────────────────────────────────────
vim.g.mapleader = ","

-- ── NODE PATH (coc.nvim) ─────────────────────────────────────────────────────
-- Inside AppImage APPDIR is set; the bundled node is used automatically.
-- Outside: falls back to PATH node or the nvm default.
local function find_node()
  local e = vim.env.COC_NODE_PATH
  if e and vim.fn.executable(e) == 1 then return e end
  if vim.env.APPDIR then
    local p = vim.env.APPDIR .. "/usr/bin/node"
    if vim.fn.executable(p) == 1 then return p end
  end
  local p = vim.fn.exepath("node")
  return p ~= "" and p or (vim.env.HOME .. "/.nvm/versions/node/v22.14.0/bin/node")
end
vim.g.coc_node_path = find_node()

-- AppImage: write coc state to real $HOME so it persists across runs
if vim.env.APPDIR then
  local p = vim.env.HOME .. "/.config/nvim-appimage/coc"
  vim.fn.mkdir(p, "p")
  vim.g.coc_config_home = p
end

-- ── COC-SETTINGS (written once on first run) ─────────────────────────────────
local coc_cfg = vim.fn.stdpath("config") .. "/coc-settings.json"
if vim.fn.filereadable(coc_cfg) == 0 then
  local f = io.open(coc_cfg, "w")
  if f then f:write([[{
  "coc.preferences.useQuickfixForLocations": true,
  "coc.preferences.jumpCommand": "edit",
  "coc.preferences.currentFunctionSymbolAutoUpdate": true,
  "suggest.autoTrigger": "trigger",
  "diagnostic.enableMessage": "jump",
  "diagnostic.virtualText": true,
  "diagnostic.virtualTextCurrentLineOnly": false,
  "clangd.path": "~/.config/coc/extensions/coc-clangd-data/install/19.1.2/clangd_19.1.2/bin/clangd",
  "clangd.arguments": [
    "--background-index", "-j=4", "--malloc-trim", "--pch-storage=memory",
    "--header-insertion=never", "--all-scopes-completion",
    "--limit-references=100", "--query-driver=/usr/bin/g++"
  ],
  "clangd.compilationDatabaseCandidates": ["${workspaceFolder}"],
  "clangd.fallbackFlags": ["-Wall", "-O2", "-pthread", "-lssl", "-lcrypto", "-lcurl"],
  "languageserver": {
    "bash": { "command": "bash-language-server", "args": ["start"], "filetypes": ["sh"] }
  }
}]]); f:close() end
end

-- ── OPTIONS ───────────────────────────────────────────────────────────────────
local o = vim.opt
o.number        = true
o.autoindent    = true
o.shiftwidth    = 4; o.softtabstop = 4; o.tabstop = 4; o.expandtab = false
o.backspace     = "indent,eol,start"
o.history       = 50
o.hlsearch      = true; o.incsearch = true; o.ignorecase = true; o.smartcase = true
o.clipboard     = "unnamed,unnamedplus"
o.mouse         = "a"
o.textwidth     = 0
o.splitbelow    = true; o.splitright = true
-- Global fold default: indent (always safe). Per-buffer autocmd upgrades to
-- treesitter expr once a parser is confirmed active, avoiding E350.
o.foldmethod    = "indent"
o.foldlevel     = 20
o.foldlevelstart= 99   -- open all folds when a file is first opened
o.diffopt:append("followwrap,algorithm:patience")
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
-- exrc=true runs unsandboxed; the BufEnter cascade loader below is used instead
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

-- ── PLUGINS ───────────────────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
o.rtp:prepend(lazypath)

-- Treesitter: nvim-treesitter is kept for its queries/ dir (richer than
-- nvim's bundled set) and for textobjects. Highlight is driven by nvim 0.11's
-- native vim.treesitter.start() called from a BufReadPost autocmd AFTER
-- lazy.setup() so plugin queries/ is already on the rtp.
-- We do NOT use the plugin's highlight module (enable=false) — on nvim 0.11
-- it conflicts with the built-in system and one silently wins depending on
-- autocmd order, which is the root cause of the persistent highlight failures.
local _ts_cfg = {
  ensure_installed = { "c","cpp","java","go","rust","python",
                       "lua","bash","json","yaml","toml","cmake" },
  auto_install  = false,
  sync_install  = false,
  highlight = {
    enable  = false,   -- highlight driven by BufReadPost autocmd below (see TSHighlightFold)
  },
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
      goto_next_start     = { ["]f"]={ query="@function.outer", desc="KEYMAPS: next function start" },
                              ["]c"]={ query="@class.outer",    desc="KEYMAPS: next class start" } },
      goto_next_end       = { ["]F"]={ query="@function.outer", desc="KEYMAPS: next function end" },
                              ["]C"]={ query="@class.outer",    desc="KEYMAPS: next class end" } },
      goto_previous_start = { ["[f"]={ query="@function.outer", desc="KEYMAPS: prev function start" },
                              ["[c"]={ query="@class.outer",    desc="KEYMAPS: prev class start" } },
      goto_previous_end   = { ["[F"]={ query="@function.outer", desc="KEYMAPS: prev function end" },
                              ["[C"]={ query="@class.outer",    desc="KEYMAPS: prev class end" } },
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

  -- lazy=false so queries/ is on rtp before any buffer opens.
  -- config() only runs cfg.setup() for textobjects/indent.
  -- Highlight is handled by the BufReadPost autocmd after lazy.setup() below.
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

  { "lewis6991/gitsigns.nvim", event="BufReadPre",
    opts = {
      signs = { add={text="+"}, change={text="~"}, delete={text="_"},
                topdelete={text="‾"}, changedelete={text="~"} },
      on_attach = function(buf)
        local gs = package.loaded.gitsigns
        local m  = function(k, f, d)
          vim.keymap.set("n", k, f, { buffer=buf, silent=true, desc=d })
        end
        m("]h", gs.next_hunk,    "KEYMAPS: next git hunk")
        m("[h", gs.prev_hunk,    "KEYMAPS: prev git hunk")
        m("<leader>hp", gs.preview_hunk, "KEYMAPS: preview hunk inline")
        m("<leader>hs", gs.stage_hunk,   "KEYMAPS: stage hunk")
        m("<leader>hu", gs.reset_hunk,   "KEYMAPS: undo/reset hunk")
      end,
    },
  },
  { "tpope/vim-fugitive", cmd={"Git","Gedit","Gdiffsplit","Gread","Gwrite"} },
  { "sindrets/diffview.nvim", cmd={"DiffviewOpen","DiffviewFileHistory","DiffviewClose"} },

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

  -- Navigation: coc → ctags (fzf picker) → searchdecl
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

vim.keymap.set("n", "<leader>gc", ":DiffviewClose<CR>",
  { silent=true, desc="KEYMAPS: close diffview" })

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
-- BufReadPost fires after FileType, so nvim's built-in treesitter highlight
-- (which runs on FileType using bundled queries) has already attached.
-- We stop() it and start() again — lazy prepends the plugin dir so
-- vim.treesitter.start() finds the richer plugin queries first.
--
-- Fold is set with vim.schedule() so it runs after the parser tree is fully
-- built. Setting foldmethod=expr synchronously in BufReadPost can evaluate
-- the foldexpr before the parse tree exists, returning 0 for every line
-- (no folds). Deferring one tick guarantees the tree is ready.
--
-- Fold keys:  zR = open all  zM = close all  za = toggle one  zo/zc = open/close
-- Note: zf (create manual fold) always gives E350 when foldmethod≠manual — expected.
--
-- *.properties / *.log get manual fold: zf to create, za/zo/zc to toggle.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("TSHighlightFold", { clear = true }),
  callback = function(ev)
    local buf  = ev.buf
    local name = vim.fn.fnamemodify(ev.file, ":t")

    -- ── highlight ──
    if vim.api.nvim_buf_line_count(buf) <= 10000
        and pcall(vim.treesitter.get_parser, buf) then
      vim.treesitter.stop(buf)
      vim.treesitter.start(buf)
    end

    -- ── fold ──
    if name:match("%.properties$") or name:match("%.log$") then
      vim.opt_local.foldmethod = "manual"
      return
    end
    local has_parser = pcall(vim.treesitter.get_parser, buf)
    if has_parser then
      -- defer one tick: parser tree must be built before foldexpr is evaluated
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        local win = vim.fn.bufwinid(buf)
        if win == -1 then return end          -- buffer not visible, skip
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
-- To add a language: add one block. build/run use % (file) and %< (no extension).
-- rg_types: ripgrep --type flags for scoped :Rg in that filetype.
local languages = {
  {
    pattern  = {"c","cpp"},
    tabs     = { size=4, expand=false },
    build    = "g++ -g -Wall -Wextra -O2 -std=c++17 % -o %<",
    run      = "./%<",
    rg_types = "--type c --type cpp",
  },
  {
    pattern  = "java",
    tabs     = { size=2, expand=true },
    build    = "javac %",
    run      = "java %<",
  },
  {
    pattern  = "rust",
    tabs     = { size=2, expand=true },
    build    = "rustc % -o /tmp/%<",
    run      = "/tmp/%<",
  },
  {
    pattern  = "go",
    tabs     = { size=4, expand=false },  -- Go requires real tabs
    run      = "go run .",
  },
  {
    pattern  = "python",
    tabs     = { size=4, expand=true },
    run      = "python3 %",
  },
  {
    pattern  = "sh",
    tabs     = { size=2, expand=true },
    run      = "bash %",
  },
  {
    pattern  = {"lua","vim"},
    tabs     = { size=2, expand=true },
  },
  -- Add new languages here.
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
  if lang.build then
    vim.keymap.set("n", "<F8>", ":w<CR>:!"..lang.build.."<CR>",
      { buffer=true, silent=true, desc="KEYMAPS: build" })
  end
  if lang.build and lang.run then
    vim.keymap.set("n", "<F9>", ":w<CR>:!"..lang.build.." && "..lang.run.."<CR>",
      { buffer=true, silent=true, desc="KEYMAPS: build and run" })
  elseif lang.run then
    vim.keymap.set("n", "<F9>", ":w<CR>:!"..lang.run.."<CR>",
      { buffer=true, silent=true, desc="KEYMAPS: run" })
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

-- ── MAKE / BUILD INTEGRATION ─────────────────────────────────────────────────
-- F5=run  F6=clean  F7=build  (project-level make; distinct from F8/F9 per-file)
local function has_makefile()
  return vim.fn.filereadable("Makefile")==1 or vim.fn.filereadable("makefile")==1
end
local _make_ft = {}
for _, lang in ipairs(languages) do
  local pats = type(lang.pattern)=="table" and lang.pattern or {lang.pattern}
  for _, p in ipairs(pats) do if lang.run then _make_ft[p] = lang.run end end
end

vim.api.nvim_create_user_command("Make", function(opts)
  vim.cmd("w")
  local lines
  if has_makefile() then
    lines = vim.fn.systemlist("make "..opts.args.." 2>&1")
  else
    local cmd = _make_ft[vim.bo.filetype]
    if not cmd then
      vim.notify("No Makefile and no runner for "..vim.bo.filetype, vim.log.levels.WARN); return
    end
    lines = vim.fn.systemlist(vim.fn.expandcmd(cmd).." 2>&1")
  end
  vim.fn.setqflist({}, "r", { lines=lines })
  vim.cmd("copen | wincmd p")
  if #vim.fn.getqflist() > 0 then vim.cmd("cfirst") end
end, { nargs="?" })

vim.keymap.set("n", "<F5>", function() vim.cmd(has_makefile() and "Make run"   or "Make") end, { silent=true, desc="KEYMAPS: run (make)" })
vim.keymap.set("n", "<F6>", function() if has_makefile() then vim.cmd("Make clean") end end,   { silent=true, desc="KEYMAPS: clean (make)" })
vim.keymap.set("n", "<F7>", function() vim.cmd(has_makefile() and "Make build" or "Make") end, { silent=true, desc="KEYMAPS: build (make)" })

-- ── TEMPLATES ─────────────────────────────────────────────────────────────────
do
  local name  = vim.trim(vim.fn.system("git config user.name"))
  local email = vim.trim(vim.fn.system("git config user.email"))
  vim.g.code_author = name.." ("..email..")"
end
local function tpl_dir()
  return vim.env.APPDIR and (vim.env.APPDIR.."/usr/share/nvim/templates")
      or (vim.fn.stdpath("config").."/templates")
end
vim.api.nvim_create_user_command("Template", function()
  local ftype = vim.bo.filetype ~= "" and vim.bo.filetype or vim.fn.expand("%:e")
  local path  = tpl_dir().."/template."..ftype
  if vim.fn.filereadable(path)==0 then
    vim.notify("Template not found: "..path, vim.log.levels.WARN); return
  end
  local out, cursor = {}, {0,0}
  for row, line in ipairs(vim.fn.readfile(path)) do
    line = line:gsub("{{FILE}}",   vim.fn.expand("%:t"))
                :gsub("{{AUTHOR}}", vim.g.code_author)
                :gsub("{{DATE}}",   vim.fn.strftime("%B %d, %Y, %I:%M %p"))
    local ci = line:find("{{CURSOR}}")
    if ci then cursor={row,ci}; line=line:gsub("{{CURSOR}}","") end
    table.insert(out, line)
  end
  vim.fn.append(0, out)
  if cursor[1] ~= 0 then vim.fn.cursor(cursor[1], cursor[2]) end
end, {})

-- ── BUILD INFO (AppImage) ─────────────────────────────────────────────────────
-- :NvimBuildInfo prints the commit / datetime / author embedded at build time.
vim.api.nvim_create_user_command("NvimBuildInfo", function()
  local info_file = vim.env.APPDIR and (vim.env.APPDIR .. "/build-info.txt") or nil
  if info_file and vim.fn.filereadable(info_file) == 1 then
    for _, line in ipairs(vim.fn.readfile(info_file)) do
      vim.notify(line, vim.log.levels.INFO)
    end
  else
    vim.notify("Not running from an AppImage (no build-info.txt found)", vim.log.levels.WARN)
  end
end, {})
