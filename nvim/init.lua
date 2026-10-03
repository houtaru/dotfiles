-- ~/.config/nvim/init.lua  (Neovim 0.12)
-- Mental model: keys move the cursor or the eyes; commands do something.
-- Custom commands are nouns (:Rg :Diff :Code :Copy :Preview); <Tab>/autocomplete lists their verbs.

-- ── GLOBALS ───────────────────────────────────────────────────────────────────
vim.g.mapleader      = ","
vim.g.maplocalleader = ","

vim.g.ts_parsers = {
    "c", "cpp", "rust", "go", "python", "java", "lua", "bash", "json", "yaml", "toml",
    "cmake", "make", "markdown", "markdown_inline", "diff", "gitcommit", "vim", "vimdoc",
}

-- ── PLUGINS ───────────────────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
        error("lazy.nvim bootstrap failed; plugins are not loaded", 0)
    end
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
                ["<Down>"]    = { "select_next", "fallback_to_mappings" },
                ["<Up>"]      = { "select_prev", "fallback_to_mappings" },
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
            cmdline  = { enabled = false },
            sources  = {
                default = { "lsp", "path", "snippets", "buffer" },
            },
            snippets = { preset = "default" },
            signature = { enabled = true },
        },
    },

    { "nvim-treesitter/nvim-treesitter",
        branch = "main", build = ":TSUpdate",
        event  = "BufReadPost",
        config = function()
            local ts = require("nvim-treesitter")
            ts.setup {}
            if vim.g.ts_skip_auto_install then return end
            local installed = ts.get_installed()
            local missing = vim.tbl_filter(function(l) return not vim.list_contains(installed, l) end, vim.g.ts_parsers)
            if #missing == 0 then return end
            ts.install(missing, { max_jobs = 2 })
        end,
    },

    { "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main", event = "BufReadPost",
        config = function()
            require("nvim-treesitter-textobjects").setup { select = { lookahead = true } }
            local sel = require("nvim-treesitter-textobjects.select")
            local mov = require("nvim-treesitter-textobjects.move")
            local function obj(lhs, query, desc)
                vim.keymap.set({ "x", "o" }, lhs, function() sel.select_textobject(query, "textobjects") end, { desc = desc })
            end
            local function jump(lhs, fn, query, desc)
                vim.keymap.set({ "n", "x", "o" }, lhs, function() mov[fn](query, "textobjects") end, { desc = desc })
            end
            obj("af", "@function.outer",  "Select function (outer)")
            obj("if", "@function.inner",  "Select function (inner)")
            obj("ac", "@class.outer",     "Select class (outer)")
            obj("ic", "@class.inner",     "Select class (inner)")
            obj("aa", "@parameter.outer", "Select argument (outer)")
            obj("ia", "@parameter.inner", "Select argument (inner)")
            jump("]f", "goto_next_start",     "@function.outer", "Next function start")
            jump("[f", "goto_previous_start", "@function.outer", "Prev function start")
            jump("]k", "goto_next_start",     "@class.outer",    "Next class start")
            jump("[k", "goto_previous_start", "@class.outer",    "Prev class start")
        end,
    },

    { "echasnovski/mini.diff", event = "BufReadPost",
        config = function()
            require("mini.diff").setup({
                view  = { style = "sign", signs = { add = "+", change = "~", delete = "_" } },
                delay = { text_change = 100 },
                mappings = { apply = "", reset = "", textobject = "" },
            })
        end,
    },

    { "tpope/vim-fugitive",
        cmd = { "Git", "G", "Gedit", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "GBrowse", "Gclog", "Gllog" },
        keys = {
            { "<leader>gh", "<cmd>diffget //2<CR>", mode = { "n", "v" }, desc = "Merge: take hunk from LEFT (target, //2)" },
            { "<leader>gl", "<cmd>diffget //3<CR>", mode = { "n", "v" }, desc = "Merge: take hunk from RIGHT (merge, //3)" },
        },
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
                keymaps = {
                    ["g?"]   = "actions.show_help",
                    ["q"]    = "actions.close",
                },
            })
        end,
    },

    { "ibhagwan/fzf-lua", lazy=true,
        cmd  = "FzfLua",
        keys = {
            { "<leader>f", function() require("fzf-lua").files() end, desc="Find file" },
            { "<leader>F", function() require("fzf-lua").files({ no_ignore = true, hidden = true }) end, desc="Find file (incl. ignored + hidden)" },
            { "<leader>e", function() require("fzf-lua").buffers() end, desc="Buffers" },
            { "<leader>r", function() require("fzf-lua").oldfiles() end, desc="Recent files" },
            { "<leader>/", function() require("fzf-lua").live_grep() end, desc="Live grep" },
            { "<leader>?", function() require("fzf-lua").keymaps() end, desc="Search keymaps" },
            { "<leader>:", function() require("fzf-lua").commands() end, desc="Search commands" },
        },
    },
}, {
    rocks = { enabled = false },
    performance = { rtp = { disabled_plugins = { "gzip","tarPlugin","tohtml","tutor","zipPlugin","netrwPlugin","matchit","matchparen" } } },
})

-- ── OPTIONS ───────────────────────────────────────────────────────────────────
local o = vim.opt
o.number        = true
o.fileencodings = "utf-8"
o.ignorecase    = true; o.smartcase = true
o.mouse         = "a"
o.splitbelow    = true; o.splitright = true
o.foldmethod    = "indent"; o.foldlevel = 20
o.diffopt:append("followwrap,algorithm:histogram")
o.autowrite     = true
o.timeoutlen    = 500
o.display       = "lastline,uhex"
o.colorcolumn   = "80,100"
o.switchbuf     = "useopen,usetab"
o.backup        = false; o.writebackup = false
o.updatetime    = 250; o.signcolumn = "yes"
o.background    = "dark"
o.secure        = true
o.exrc          = true
o.scrolloff     = 8; o.sidescrolloff = 8
o.winborder     = "rounded"
o.clipboard     = "unnamedplus"
o.list = true
o.listchars = {
    eol="¬", trail="·", nbsp="◇", tab="→ ",
    extends="▸", precedes="◂", multispace="···⬝", leadmultispace="│   ",
}
-- Built-in opt plugin :Undotree
vim.cmd.packadd("nvim.undotree")

-- Only the focused window gets relative numbers and cursorline.
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

-- ── CMDLINE ───────────────────────────────────────────────────────────────────
-- Native autocompletion: suggestions pop up while typing ':' commands and '/' '?' searches.
o.wildmode    = "noselect:lastused,full"
o.wildoptions = "pum,fuzzy"
local cmdline_grp = vim.api.nvim_create_augroup("CmdlineAutocomplete", { clear=true })
vim.api.nvim_create_autocmd("CmdlineChanged", {
    group    = cmdline_grp,
    pattern  = { ":", "/", "?" },
    callback = function() vim.fn.wildtrigger() end,
})

-- Short popup (scrolls with <Tab>/arrows); scoped to the cmdline so insert-mode menus keep their size.
vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = cmdline_grp, pattern = { ":", "/", "?" }, callback = function() vim.o.pumheight = 5 end,
})
vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = cmdline_grp, pattern = { ":", "/", "?" }, callback = function() vim.o.pumheight = 0 end,
})

-- Keep <Up>/<Down> as history recall even while the popup is open.
vim.keymap.set("c", "<Up>",   function() return vim.fn.wildmenumode() == 1 and "<C-e><Up>"   or "<Up>"   end, { expr=true, desc="History back" })
vim.keymap.set("c", "<Down>", function() return vim.fn.wildmenumode() == 1 and "<C-e><Down>" or "<Down>" end, { expr=true, desc="History forward" })

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
    float = { source = true },
    jump = {
        on_jump = function(_, bufnr)
            vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
        end,
    },
})

-- ── COLORSCHEME ───────────────────────────────────────────────────────────────
vim.cmd.colorscheme("codedark")
local function apply_transparency()
    local clear = { "Normal","NormalNC","NormalFloat","LineNr","SignColumn","VertSplit","WinSeparator","EndOfBuffer","Folded" }
    for _, g in ipairs(clear) do vim.api.nvim_set_hl(0, g, { bg="none", ctermbg="none" }) end
    vim.api.nvim_set_hl(0, "LspInlayHint", { fg="#808080", bg="none", ctermbg="none" })
    vim.api.nvim_set_hl(0, "CursorLine", { bg="#2a2d2e", ctermbg=236 })
end
apply_transparency()
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("Transparency", { clear = true }),
    callback = apply_transparency,
})

-- ── NATIVE TMUX NAVIGATION ───────────────────────────────────────────────────
local function tmux_nav(dir)
    local win = vim.api.nvim_get_current_win()
    vim.cmd("wincmd " .. dir)
    if win == vim.api.nvim_get_current_win() and vim.env.TMUX and vim.env.TMUX ~= "" then
        local tmux_dir = { h = "L", j = "D", k = "U", l = "R" }
        local ok, err = pcall(vim.system, { "tmux", "select-pane", "-" .. tmux_dir[dir] }, { text = true }, function(res)
            if res.code == 0 then return end
            vim.schedule(function()
                vim.notify("tmux select-pane failed: " .. vim.trim(res.stderr or ""), vim.log.levels.WARN)
            end)
        end)
        if not ok then vim.notify("tmux select-pane failed: " .. err, vim.log.levels.WARN) end
    end
end
vim.keymap.set({"n","t"}, "<C-h>", function() tmux_nav("h") end, { silent = true, desc = "Window/tmux pane left" })
vim.keymap.set({"n","t"}, "<C-j>", function() tmux_nav("j") end, { silent = true, desc = "Window/tmux pane down" })
vim.keymap.set({"n","t"}, "<C-k>", function() tmux_nav("k") end, { silent = true, desc = "Window/tmux pane up" })
vim.keymap.set({"n","t"}, "<C-l>", function() tmux_nav("l") end, { silent = true, desc = "Window/tmux pane right" })

-- ── NATIVE STATUSLINE ─────────────────────────────────────────────────────────
-- mini.diff has no branch name; cache it per buffer, refreshed asynchronously.
local function update_branch(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" or vim.bo[buf].buftype ~= "" then return end
    local dir = vim.fs.dirname(name)
    if not vim.uv.fs_stat(dir) then return end
    vim.system({ "git", "branch", "--show-current" }, { cwd = dir, text = true }, function(res)
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) then return end
            local branch = res.code == 0 and vim.trim(res.stdout) or nil
            -- empty output means detached HEAD
            -- false (not nil) outside a repo, so BufEnter does not retry git on every visit.
            vim.b[buf].git_branch = branch and (branch ~= "" and branch or "HEAD") or false
            vim.cmd.redrawstatus()
        end)
    end)
end
local branch_grp = vim.api.nvim_create_augroup("GitBranch", { clear=true })
-- BufEnter only fills a missing value (one git spawn per buffer); FocusGained and
-- FugitiveChanged are where the branch can actually have changed.
vim.api.nvim_create_autocmd("BufEnter", {
    group = branch_grp,
    callback = function(ev) if vim.b[ev.buf].git_branch == nil then update_branch(ev.buf) end end,
})
-- BufFilePost: :saveas/:file renames the buffer, possibly into another repo.
vim.api.nvim_create_autocmd({ "FocusGained", "BufFilePost" }, {
    group = branch_grp, callback = function(ev) update_branch(ev.buf) end,
})
vim.api.nvim_create_autocmd("User", {
    group = branch_grp, pattern = "FugitiveChanged", callback = function() update_branch(0) end,
})

local function stl_escape(s) return (s:gsub("%%", "%%%%")) end

function _G.statusline()
    local mode = vim.api.nvim_get_mode().mode:sub(1,1)
    local file = vim.fn.expand("%:p:~:.")
    local git = ""
    if vim.b.git_branch then
        git = string.format(" [%s]", vim.b.git_branch)
    end
    local diag = vim.diagnostic.status()
    local progress = vim.ui.progress_status()
    return string.format(" %s | %s%s %s %%= %s %s | %d:%d ", mode, stl_escape(file), stl_escape(git),
        diag, progress, vim.bo.filetype, vim.fn.line("."), vim.fn.col("."))
end
o.statusline = "%!v:lua.statusline()"
o.laststatus = 3

-- ── NATIVE LSP (0.12) ────────────────────────────────────────────────────────
-- Own LSP keys are kept (gd gy gi gr); delete the gr* defaults so `gr` fires without a timeoutlen wait.
-- pcall: the defaults are already gone when the config is re-sourced.
for _, lhs in ipairs({ "grn", "grr", "gri", "grt", "grx" }) do pcall(vim.keymap.del, "n", lhs) end
pcall(vim.keymap.del, { "n", "x" }, "gra")

-- Colors come from treesitter only: no recolor flicker when the server catches up, less server load.
vim.lsp.semantic_tokens.enable(false)

vim.lsp.config("*", {
    exit_timeout = 1000,
    root_markers = { ".git", "tags", ".editorconfig"},
})

vim.lsp.config("lua_ls", { cmd = { "lua-language-server" }, settings = { Lua = { diagnostics = { globals = { "vim" } } } } })
vim.lsp.config("rust_analyzer", { cmd = { "rust-analyzer" } })
vim.lsp.config("gopls",         { cmd = { "gopls" } })
vim.lsp.config("pyright",       { cmd = { "pyright-langserver", "--stdio" } })
vim.lsp.config("clangd", {
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    cmd = { "clangd"
        , "-j=2"
        , "--background-index"
        , "--background-index-priority=low"
        , "--malloc-trim"
        , "--clang-tidy"
        , "--header-insertion=iwyu"
        , "--all-scopes-completion"
        , "--limit-references=100"
        , "--query-driver=/usr/bin/g++"
    },
})

-- Per buffer+client augroups (clear=true) make a re-attach replace rather than stack the
-- autocmds; the client id keeps a second client on the buffer from clearing the first one's
-- hooks, and deleting on detach/wipeout stops groups piling up.
local function client_buf_augroup(prefix, bufnr, client_id)
    local grp = vim.api.nvim_create_augroup(prefix .. bufnr .. "_" .. client_id, { clear = true })
    vim.api.nvim_create_autocmd({ "LspDetach", "BufWipeout" }, {
        buf = bufnr,
        group = grp,
        callback = function(ev)
            if ev.event == "LspDetach" and ev.data.client_id ~= client_id then return end
            vim.api.nvim_del_augroup_by_id(grp)
        end,
    })
    return grp
end

vim.lsp.config("mpls", {
    cmd = {
        "mpls",
        "--no-auto",
        "--tabs",
        "--theme", "light",
        "--enable-emoji",
        "--enable-footnotes",
        "--enable-wikilinks",
    },
    root_markers = { ".git" },
    filetypes = { "markdown" },
    on_attach = function(client, bufnr)
        local function notify_focus()
            if not client:is_stopped() then
                client:notify("mpls/editorDidChangeFocus", {
                    uri = vim.uri_from_bufnr(bufnr),
                })
            end
        end

        notify_focus()
        vim.api.nvim_create_autocmd("BufEnter", {
            buf = bufnr,
            group = client_buf_augroup("MplsFocus_", bufnr, client.id),
            callback = notify_focus,
            desc = "mpls: notify buffer focus changed",
        })
    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    group    = vim.api.nvim_create_augroup("LspAttach", { clear=true }),
    callback = function(ev)
        local buf = ev.buf
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local is_file = vim.uri_from_bufnr(buf):match("^file://") ~= nil
        if is_file and client and client:supports_method("textDocument/inlayHint", buf) then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
        end

        local m   = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buf=buf, silent=true, desc=desc })
        end

        -- K (hover) is an nvim default on attach.
        m("n", "gd", vim.lsp.buf.definition,      "Go to definition")
        m("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
        m("n", "gi", vim.lsp.buf.implementation,  "Go to implementation")
        m("n", "gr", vim.lsp.buf.references,      "List references")
        m("n", "gl", vim.diagnostic.open_float,   "Diagnostic info")
        m("n", "[g", function() vim.diagnostic.jump({ count = -1 }) end, "Prev diagnostic")
        m("n", "]g", function() vim.diagnostic.jump({ count = 1 }) end,  "Next diagnostic")

        if is_file and client and client:supports_method("textDocument/documentHighlight", buf) then
            local augrp = client_buf_augroup("LspDocHL_", buf, client.id)
            vim.api.nvim_create_autocmd("CursorHold", {
                buf      = buf,
                group    = augrp,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({"CursorMoved","InsertEnter"}, {
                buf      = buf,
                group    = augrp,
                callback = vim.lsp.buf.clear_references,
            })
        end
    end,
})

-- ── EDITORCONFIG ──────────────────────────────────────────────────────────────
-- container/podman container-name grammar; the name is also used as a cache directory name.
-- nvim's editorconfig parser lowercases values, so containers with uppercase names can't match.
local function valid_container_name(name)
    return type(name) == "string" and name:match("^[%w][%w_.-]*$") ~= nil
end

local function parse_bool(v)
    if v == "true" then return true end
    if v == "false" then return false end
    return nil, "expected true or false"
end

-- Each parser returns value, err. An invalid container_name keeps its value so container()
-- can refuse it; reading it as "no container" would silently start a host LSP instead.
local EC_PROPS = {
    enable_lsp          = parse_bool,
    exclude_ignorefiles = parse_bool,
    exclude_hidden      = parse_bool,
    exclude_files       = function(v) return v end,
    container_name      = function(v)
        if v == "" then return nil end
        return v, not valid_container_name(v) and "expected [A-Za-z0-9][A-Za-z0-9_.-]*" or nil
    end,
}

-- nvim's editorconfig runtime overwrites vim.b.editorconfig with the raw strings after the
-- property hooks run (and replaces it on every read), so the hooks only validate and ec()
-- derives the typed view from it on demand.
for name, parse in pairs(EC_PROPS) do
    require("editorconfig").properties[name] = function(bufnr, val)
        local _, err = parse(val)
        if err then
            vim.notify(("editorconfig for %s: invalid %s = '%s' (%s)"):format(
                vim.api.nvim_buf_get_name(bufnr), name, val, err), vim.log.levels.ERROR)
        end
    end
end

local function ec(bufnr)
    local raw, typed = vim.b[bufnr].editorconfig or {}, {}
    for name, parse in pairs(EC_PROPS) do
        if raw[name] ~= nil then typed[name] = (parse(raw[name])) end
    end
    return typed
end

-- ── QUICKFIX & SEARCH ─────────────────────────────────────────────────────────
local function qf_is_open()
    for _, w in ipairs(vim.fn.getwininfo()) do if w.quickfix == 1 then return true end end
    return false
end
local function qf_in_tab()
    for _, b in ipairs(vim.fn.tabpagebuflist()) do
        if vim.bo[b].buftype == "quickfix" then return true end
    end
    return false
end
local function qf_open_keep_focus()
    vim.cmd("copen | wincmd p")
end

local function rg_qf(pattern, extra_flags, title, tokens)
    if not pattern or pattern == "" then
        vim.notify("Rg: missing pattern", vim.log.levels.WARN); return
    end
    local args = { "rg","--column","--line-number","--no-heading","--smart-case" }

    local cfg = ec(0)
    if not vim.F.if_nil(cfg.exclude_ignorefiles, true) then
        table.insert(args, "--no-ignore")
    end
    if not vim.F.if_nil(cfg.exclude_hidden, true) then
        table.insert(args, "--hidden")
    end
    if cfg.exclude_files and cfg.exclude_files ~= "" then
        for pat in cfg.exclude_files:gmatch("[^,]+") do
            pat = vim.trim(pat)
            if pat ~= "" then
                table.insert(args, "-g")
                table.insert(args, "!" .. pat)
            end
        end
    end

    for _, f in ipairs(extra_flags or {}) do table.insert(args, f) end
    if tokens then
        for _, t in ipairs(tokens) do table.insert(args, t) end
    else
        table.insert(args, "--"); table.insert(args, pattern)
    end
    vim.system(args, { text=true }, function(result)
        vim.schedule(function()
            if result.code == 1 then
                vim.notify("Rg: no results for "..pattern, vim.log.levels.INFO); return
            end
            if result.code ~= 0 then
                vim.notify("Rg: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
                if (result.stdout or "") == "" then return end
            end
            vim.fn.setqflist({}, "r", {
                lines = vim.split(result.stdout or "", "\n", { trimempty=true }),
                title = title or (":Rg "..pattern),
            })
            qf_open_keep_focus()
        end)
    end)
end

vim.keymap.set("n", "<leader>q", function() vim.cmd(qf_is_open() and "cclose" or "copen") end,
    { silent=true, desc="Toggle quickfix" })
vim.keymap.set("n", "<leader>n", function() vim.cmd(qf_in_tab() and "cnext" or "bnext") end,
    { desc="Next qf item / buffer" })
vim.keymap.set("n", "<leader>b", function() vim.cmd(qf_in_tab() and "cprev" or "bprev") end,
    { desc="Prev qf item / buffer" })

vim.keymap.set("n", "g]", function()
    local w = vim.fn.expand("<cword>")
    local t = vim.fn.taglist("^"..w.."$")
    if #t == 0 then return vim.notify("No tags: "..w, vim.log.levels.WARN) end
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

-- Shared by the global mapping and the filetype-scoped ones (set_rg), which add rg flags.
local function visual_rg(flags, title)
    return function()
        local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
        if #lines == 0 then return end
        local f = vim.list_extend(vim.deepcopy(flags or {}), { "-F" })
        if #lines > 1 then table.insert(f, "-U") end
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        rg_qf(table.concat(lines, "\n"), f, title)
    end
end

vim.keymap.set("v", "gw", visual_rg(nil, "Visual Search"), { desc = "Search selection to quickfix" })

vim.api.nvim_create_user_command("Rg", function(opts)
    rg_qf(opts.args, {}, ":Rg "..opts.args, opts.fargs)
end, { nargs="+", desc="Rg (respects ignores; -uu for all; inline flags any order)" })

-- ── KEYMAPS ───────────────────────────────────────────────────────────────────
-- Navigation/search/jump/review only; actions live in the noun commands below.
vim.keymap.set("n", "<C-N>", function() require("oil").toggle_float() end, { silent=true, desc="Oil (float)" })
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>s", "<cmd>split<CR>",  { desc = "Horizontal split" })
vim.keymap.set("n", "<leader>w", "<cmd>bw<CR>",     { desc = "Close buffer" })
vim.keymap.set("n", "<leader>d", function() require("mini.diff").toggle_overlay(0) end, { desc = "Toggle inline diff" })

-- ── NOUN COMMANDS ────────────────────────────────────────────────────────────
-- :Noun [verb] [args]. `fallback` handles a first word that is not a verb (e.g. a git rev).
local function noun_command(name, desc, verbs, fallback, complete_first)
    local names = vim.tbl_keys(verbs)
    table.sort(names)
    vim.api.nvim_create_user_command(name, function(opts)
        local verb, args = opts.fargs[1], vim.list_slice(opts.fargs, 2)
        if verbs[verb] then return verbs[verb].run(args, opts) end
        if verb == nil and verbs[""] then return verbs[""].run(args, opts) end
        if verb ~= nil and fallback then return fallback(verb, args, opts) end
        vim.notify((":%s: unknown verb '%s' (expected: %s)"):format(name, tostring(verb), table.concat(names, ", ")), vim.log.levels.ERROR)
    end, {
        nargs = "*", range = true, desc = desc,
        complete = function(arglead, cmdline)
            local words = vim.split(cmdline:sub(1, #cmdline - #arglead), "%s+", { trimempty = true })
            -- Drop modifiers/ranges before the noun (":vert Diff", ":'<,'> Code").
            for i, w in ipairs(words) do
                if w:match(name .. "!?$") then words = vim.list_slice(words, i); break end
            end
            local cands
            if #words <= 1 then
                cands = vim.tbl_filter(function(v) return v ~= "" end, names)
                if complete_first then vim.list_extend(cands, complete_first()) end
            else
                local v = verbs[words[2]]
                cands = v and v.complete and v.complete(#words - 1) or {}
            end
            return arglead == "" and cands or vim.fn.matchfuzzy(cands, arglead)
        end,
    })
end

local function range_of(opts)
    if opts.range == 0 then return nil end
    return { start = { opts.line1, 0 }, ["end"] = { opts.line2, #vim.fn.getline(opts.line2) } }
end

noun_command("Code", "Code actions (LSP): action rename format symbols diag", {
    action  = { run = function(_, opts) vim.lsp.buf.code_action({ range = range_of(opts) }) end },
    rename  = { run = function(args) vim.lsp.buf.rename(args[1]) end },
    format  = { run = function(_, opts) vim.lsp.buf.format({ range = range_of(opts) }) end },
    symbols = { run = function() vim.lsp.buf.document_symbol() end },
    diag    = {
        run = function(args)
            if args[1] == nil then
                local on = vim.diagnostic.is_enabled({ bufnr = 0 })
                vim.diagnostic.enable(not on, { bufnr = 0 })
                vim.notify("Diagnostics " .. (on and "off" or "on") .. " (buffer)")
            elseif args[1] == "qf" and args[2] == nil then
                vim.diagnostic.setqflist({ open = true, bufnr = 0 })
            elseif args[1] == "qf" and args[2] == "all" then
                vim.diagnostic.setqflist({ open = true })
            else
                vim.notify(":Code diag [qf [all]]", vim.log.levels.ERROR)
            end
        end,
        complete = function(pos) return ({ { "qf" }, { "all" } })[pos] or {} end,
    },
})

local function copy(text)
    vim.fn.setreg("+", text)
    vim.notify("Copied: " .. text)
end

local SymbolKind = vim.lsp.protocol.SymbolKind
local SCOPE_KINDS = {
    [SymbolKind.Namespace] = true, [SymbolKind.Class] = true, [SymbolKind.Method] = true,
    [SymbolKind.Interface] = true, [SymbolKind.Function] = true, [SymbolKind.Struct] = true,
}

-- C++ scope path of the cursor (ns::Class::method) from LSP document symbols.
local function copy_scope()
    local params = { textDocument = vim.lsp.util.make_text_document_params() }
    vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result)
        if err or not result then return vim.notify("Copy scope: no document symbols (LSP attached?)", vim.log.levels.WARN) end
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        local path = {}
        local function walk(syms)
            for _, s in ipairs(syms) do
                local r = s.range or (s.location and s.location.range)
                if r and r.start.line <= row and r["end"].line >= row then
                    if SCOPE_KINDS[s.kind] then
                        table.insert(path, s.name)
                    end
                    if s.children then walk(s.children) end
                    return
                end
            end
        end
        walk(result)
        if #path == 0 then return vim.notify("Copy scope: no function context") end
        copy(table.concat(path, "::"))
    end)
end

noun_command("Copy", "Copy to clipboard: path rel ref scope", {
    path  = { run = function() copy(vim.fn.expand("%:p")) end },
    rel   = { run = function() copy(vim.fn.expand("%:.")) end },
    ref   = { run = function(_, opts)
        local lines = opts.range > 0 and opts.line1 ~= opts.line2 and (opts.line1 .. "-" .. opts.line2) or tostring(opts.line1)
        copy(vim.fn.expand("%:.") .. ":" .. lines)
    end },
    scope = { run = copy_scope },
})

vim.api.nvim_create_user_command("Preview", function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype ~= "markdown" then
        return vim.notify(":Preview: markdown buffers only", vim.log.levels.ERROR)
    end

    local function open_preview(client)
        client:exec_cmd({ title = "Preview markdown with mpls", command = "open-preview" }, { bufnr = buf })
    end

    local client = vim.lsp.get_clients({ bufnr = buf, name = "mpls" })[1]
    if client then return open_preview(client) end
    if vim.fn.executable("mpls") ~= 1 then
        return vim.notify(":Preview: mpls not installed / not on PATH", vim.log.levels.ERROR)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
        buf = buf,
        callback = function(args)
            local attached = vim.lsp.get_client_by_id(args.data.client_id)
            if not attached or attached.name ~= "mpls" then return end
            open_preview(attached)
            return true
        end,
        desc = "mpls: open preview once attached",
    })

    -- Loading blink registers its LSP capabilities; must precede client start.
    require("blink.cmp")
    local config = vim.deepcopy(vim.lsp.config.mpls)
    config.root_dir = vim.fs.root(buf, config.root_markers)
        or vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
    vim.lsp.start(config, {
        bufnr = buf,
        reuse_client = function(c) return c.name == "mpls" end,
    })
end, { desc = "Markdown preview in browser (mpls)" })

-- Once :Preview started mpls, the preview should follow focus into markdown files opened later.
-- Ignores enable_lsp like :Preview does; skips special buffers (LSP hover floats are markdown too).
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("MplsFollow", { clear = true }),
    pattern = "markdown",
    callback = function(ev)
        if vim.bo[ev.buf].buftype ~= "" or vim.api.nvim_buf_get_name(ev.buf) == "" then return end
        local client = vim.lsp.get_clients({ name = "mpls" })[1]
        if client then vim.lsp.buf_attach_client(ev.buf, client.id) end
    end,
    desc = "mpls: attach markdown buffers to the running preview server",
})

-- ── :Diff (review with mini.diff) ────────────────────────────────────────────
-- Base nil = git index (mini.diff's default git source, supports staging).
-- Base set = every buffer compares against that commit via a custom source.
local diff_base = nil ---@type { label: string, sha: string, root: string }?

-- Bounded: this also runs inside cmdline completion, where a hung git would freeze the UI,
-- so callers there pass a short timeout; :Diff commands may legitimately take longer on big repos.
local function git(args, cwd, timeout_ms)
    timeout_ms = timeout_ms or 1000
    local res = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait(timeout_ms)
    if res and res.code == 0 then return vim.trim(res.stdout), "" end
    -- On timeout :wait() kills the process and yields code 124, or nil if the exit has not
    -- been reaped yet.
    if not res or res.code == 124 then return nil, ("git %s timed out after %gs"):format(args[1], timeout_ms / 1000) end
    return nil, vim.trim(res.stderr or "")
end

local DIFF_GIT_MS = 10000

local function git_root(dir)
    return git({ "rev-parse", "--show-toplevel" }, dir, DIFF_GIT_MS)
end

local function buf_dir()
    local name = vim.api.nvim_buf_get_name(0)
    -- oil://, fugitive://, quickfix, new files in missing dirs: fall back to cwd
    if name == "" or vim.bo.buftype ~= "" or name:match("^%a[%w+.-]*://") then return vim.fn.getcwd() end
    local dir = vim.fs.dirname(name)
    return vim.uv.fs_stat(dir) and dir or vim.fn.getcwd()
end

-- "X..." means "since this branch left X" (merge-base with HEAD), like a PR diff.
local function resolve_rev(rev)
    local root, err = git_root(buf_dir())
    if not root then return nil, err end
    local sha
    if rev:sub(-3) == "..." then
        sha, err = git({ "merge-base", rev:sub(1, -4), "HEAD" }, root, DIFF_GIT_MS)
    else
        sha, err = git({ "rev-parse", "--verify", "--quiet", rev .. "^{commit}" }, root, DIFF_GIT_MS)
    end
    if not sha then return nil, ("unknown revision '%s'%s"):format(rev, err ~= "" and (": " .. err) or "") end
    return { label = rev, sha = sha, root = root }
end

local base_source = {
    name = "base",
    attach = function(buf)
        local path = vim.api.nvim_buf_get_name(buf)
        if not diff_base or path == "" or not vim.startswith(path, diff_base.root .. "/") then return false end
        local sha = diff_base.sha
        vim.system({ "git", "show", sha .. ":./" .. vim.fs.basename(path) }, { cwd = vim.fs.dirname(path), text = true }, function(res)
            vim.schedule(function()
                -- Base may have changed (:Diff index / another rev) while git show ran.
                if not vim.api.nvim_buf_is_valid(buf) or not diff_base or diff_base.sha ~= sha then return end
                -- A file missing from the base commit is entirely new: empty reference.
                require("mini.diff").set_ref_text(buf, res.code == 0 and res.stdout or "")
            end)
        end)
    end,
}

local function reattach_all()
    local md = require("mini.diff")
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "" and vim.api.nvim_buf_get_name(b) ~= "" then
            md.disable(b); md.enable(b)
        end
    end
end

local function set_base(base)
    diff_base = base
    -- New buffers pick this up too: mini.diff reads MiniDiff.config at enable time.
    require("mini.diff").config.source = base and base_source or nil
    reattach_all()
end

-- git --name-status letters → what happened to the file relative to the base.
local STATUS_LABEL = { A = "added", M = "modified", D = "deleted", R = "renamed", C = "copied", T = "type changed", U = "unmerged" }

local function changed_files(base)
    local root, rerr = base and base.root, nil
    if not root then root, rerr = git_root(buf_dir()) end
    if not root then return vim.notify(":Diff: not inside a git repository: " .. rerr, vim.log.levels.ERROR) end
    -- quotePath=false: git would otherwise C-quote non-ASCII paths ("\303\251.txt")
    local args = { "-c", "core.quotePath=false", "diff", "--name-status", "-M" }
    if base then table.insert(args, base.sha) end
    local out, err = git(args, root, DIFF_GIT_MS)
    if not out then return vim.notify(":Diff files: " .. err, vim.log.levels.ERROR) end
    -- Untracked files are new to any base, but `git diff` never lists them.
    local untracked, uerr = git({ "-c", "core.quotePath=false", "ls-files", "--others", "--exclude-standard" }, root, DIFF_GIT_MS)
    if not untracked then return vim.notify(":Diff files: " .. uerr, vim.log.levels.ERROR) end
    local label = base and base.label or "index"
    local items = {}
    for _, line in ipairs(vim.split(out, "\n", { trimempty = true })) do
        local fields = vim.split(line, "\t")
        local code = fields[1]:sub(1, 1)
        local status = STATUS_LABEL[code] or code
        -- Renames/copies list "old<TAB>new"; open the new path.
        local path = fields[#fields]
        local text = (code == "R" or code == "C") and ("[%s] %s from %s"):format(code, status, fields[2]) or ("[%s] %s"):format(code, status)
        table.insert(items, { filename = root .. "/" .. path, lnum = 1, text = text .. " vs " .. label })
    end
    for _, path in ipairs(vim.split(untracked, "\n", { trimempty = true })) do
        table.insert(items, { filename = root .. "/" .. path, lnum = 1, text = "[?] added (untracked) vs " .. label })
    end
    if #items == 0 then return vim.notify(":Diff: no changes vs " .. label) end
    vim.fn.setqflist({}, "r", { title = ":Diff files vs " .. label, items = items })
    qf_open_keep_focus()
end

local function hunk_action(action, opts)
    if diff_base then
        return vim.notify((":Diff %s: base is %s; run :Diff index first"):format(action == "apply" and "stage" or "reset", diff_base.label), vim.log.levels.ERROR)
    end
    require("mini.diff").do_hunks(0, action, { line_start = opts.line1, line_end = opts.line2 })
end

local refs_cache = {} ---@type table<string, { t: integer, refs: string[] }>
local function git_refs()
    -- Completion runs on every keystroke (wildtrigger); cache refs briefly, per repo so one
    -- repo's refs never complete in another. vim.fs.root keys without spawning git.
    local dir = buf_dir()
    local key = vim.fs.root(dir, ".git") or dir
    local entry = refs_cache[key]
    if not entry or vim.uv.now() - entry.t > 5000 then
        local out, err = git({ "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes", "refs/tags" }, dir, 1000)
        if not out then
            vim.notify_once(":Diff completion: git for-each-ref failed: " .. err, vim.log.levels.WARN)
        end
        -- Failures are cached too, so a broken repo costs one git spawn per 5s, not per keystroke.
        entry = { t = vim.uv.now(), refs = out and vim.list_extend({ "HEAD", "HEAD~1" }, vim.split(out, "\n", { trimempty = true })) or {} }
        refs_cache[key] = entry
    end
    return vim.deepcopy(entry.refs)
end

noun_command("Diff", "Review: toggle overlay | <rev> | index | files [rev] | hunks | split | stage | reset", {
    [""]   = { run = function() require("mini.diff").toggle_overlay(0) end },
    index  = { run = function() set_base(nil); vim.notify(":Diff base = index") end },
    files  = {
        run = function(args)
            if not args[1] then return changed_files(diff_base) end
            local base, err = resolve_rev(args[1])
            if not base then return vim.notify(":Diff files: " .. err, vim.log.levels.ERROR) end
            changed_files(base)
        end,
        complete = function(pos) return pos == 1 and git_refs() or {} end,
    },
    hunks  = { run = function()
        vim.fn.setqflist({}, "r", { title = ":Diff hunks", items = require("mini.diff").export("qf", { scope = "all" }) })
        qf_open_keep_focus()
    end },
    -- Side-by-side against the same base the signs/overlay use (fugitive: no arg = index).
    -- leftabove: fugitive otherwise puts the index left but a commit right; keep base always left.
    split  = { run = function()
        vim.cmd("leftabove Gvdiffsplit" .. (diff_base and (" " .. diff_base.sha) or ""))
    end },
    stage  = { run = function(_, opts) hunk_action("apply", opts) end },
    reset  = { run = function(_, opts)
        if diff_base then return hunk_action("reset", opts) end
        if vim.fn.confirm("Discard hunk(s) in lines " .. opts.line1 .. "-" .. opts.line2 .. "?", "&Yes\n&No", 2) == 1 then
            hunk_action("reset", opts)
        end
    end },
}, function(rev)
    local base, err = resolve_rev(rev)
    if not base then return vim.notify(":Diff: " .. err, vim.log.levels.ERROR) end
    set_base(base)
    vim.notify(":Diff base = " .. rev .. " (" .. base.sha:sub(1, 8) .. "); :Diff index to go back")
    changed_files(base)
end, git_refs)

-- ── FILETYPES ────────────────────────────────────────────────────────────────
vim.filetype.add({
    extension = {
        py2 = "python",
        tla = "tla",
    }
})
-- ── CONTAINER LSP FILE CACHE ─────────────────────────────────────────────────
-- Every file:// URI the LSP client converts passes through here: jump targets, but also
-- publishDiagnostics, workspace edits, etc. Paths outside cwd exist only inside the
-- container, so they are copied to $PWD/.cache/container/<name>/ to be openable.

-- client_id -> { cmd, name, root }, recorded when enable_lsp starts a container client.
-- root is the cwd at start: that is where the cache for this client lives, whatever window
-- is focused when a URI is converted later.
local container_clients = {}

-- uri_to_fname has no client context, so the container is chosen by running clients: that
-- keeps the mapping independent of window focus (diagnostics arrive async). Returns the
-- single running container, nil when none, or nil, true when several are ambiguous.
local function running_container()
    local found, n = nil, 0
    for id, c in pairs(container_clients) do
        local client = vim.lsp.get_client_by_id(id)
        if not client or client:is_stopped() then
            container_clients[id] = nil
        elseif not found or found.name ~= c.name then
            found, n = c, n + 1
        end
    end
    if n > 1 then return nil, true end
    return found
end

-- nil: no container for this buffer (host LSP). nil, err: configured but unusable, which
-- must not degrade to a host LSP.
local function container(bufnr)
    local name = ec(bufnr).container_name
    local cmd = vim.env.CONTAINER_COMMAND
    if not name or not cmd or cmd == "" then return nil end
    if not valid_container_name(name) then
        return nil, ("invalid .editorconfig container_name '%s' (expected [A-Za-z0-9][A-Za-z0-9_.-]*)"):format(name)
    end
    return { cmd = cmd, name = name }
end

-- joinpath collapses duplicate slashes, so root "/" gives "/.cache/..." rather than "//.cache/...".
local function container_cache_root(name, root)
    return vim.fs.normalize(vim.fs.joinpath(root or vim.fn.getcwd(), ".cache/container", name))
end

-- Paths come from the language server, so they are untrusted. '..' is rejected before
-- normalize() because normalize() would silently resolve it.
local function container_cache_path(name, path, root)
    if path:sub(1, 1) ~= "/" then return nil, "not an absolute path" end
    for seg in path:gmatch("[^/]+") do
        if seg == ".." then return nil, "contains a '..' segment" end
    end
    local cache_root = container_cache_root(name, root)
    local cache_path = vim.fs.normalize(cache_root .. path)
    if not vim.startswith(cache_path, cache_root .. "/") then return nil, "escapes the cache root" end
    return cache_path
end

-- uri_to_fname runs for every diagnostic of a file: a path that failed once is neither
-- retried (each retry would block again) nor warned about again, so the user is told how to get a retry.
local failed_paths = {}
local stale_warned = {}
-- Per cache path: no refetch before this time after a failed refresh of a stale copy.
local stale_retry = {}
local function fail_path(path, msg)
    failed_paths[path] = true
    vim.notify(msg .. "; using the host file for the rest of this session (open a new nvim session to retry)", vim.log.levels.WARN)
    return path
end

-- The cache dir is shared by concurrent sessions, so it is never wiped (that deleted files
-- other sessions had open); instead a file cached before this session started may be stale
-- and is fetched again on first use. Wall-clock (os.time, not the monotonic vim.uv.now) so
-- it compares with file mtimes; kept in _G so re-sourcing does not refetch everything.
_G._container_session_start = _G._container_session_start or os.time()
local session_start = _G._container_session_start
-- Bounds refetches to one per path and session even if the written mtime is not newer
-- than session_start (clock steps back).
local refreshed = {}

-- The cache tree lives in the (untrusted) project: a committed symlink anywhere on the way
-- must not redirect reads or writes. The root (a cwd) is already a physical path.
local function physical(p)
    while not vim.uv.fs_lstat(p) do p = vim.fs.dirname(p) end
    return vim.uv.fs_realpath(p) == p
end

-- One hung container would otherwise cost the 2 s timeout per distinct path (references or
-- workspace symbols over N paths would freeze for 2N s), so a timeout or spawn failure
-- parks that container for DEAD_MS.
local DEAD_MS = 30000
local dead_until = {}
local dead_warned = {}

-- Sessions share the cache tree, and mkdir(dir, "p") fails (E739) when another session
-- creates a parent between its check and its mkdir; an existing dir is success here.
local function mkdir_p(dir)
    if vim.uv.fs_stat(dir) then return end
    mkdir_p(vim.fs.dirname(dir))
    local _, err, name = vim.uv.fs_mkdir(dir, tonumber("755", 8))
    if err and name ~= "EEXIST" then error(err, 0) end
end

-- The cache may sit on NFS shared by several hosts, where pids collide across hosts, so tmp
-- names carry the host and prune only judges pids of its own host.
local TMP_HOST = (vim.uv.os_gethostname() or ""):gsub("[^%w_.-]", "_")
if TMP_HOST == "" then TMP_HOST = "unknown" end

-- Synchronous because uri_to_fname callers need the path now; the timeout bounds the stall.
local function sync_container_file(c, path)
    if failed_paths[path] then return path end
    local cache_path, err = container_cache_path(c.name, path, c.root)
    if not cache_path then
        return fail_path(path, ("container %s: not caching %s: %s"):format(c.name, path, err))
    end
    if not physical(cache_path) then
        return fail_path(path, ("container %s: not caching %s: cache path goes through a symlink"):format(c.name, path))
    end
    local st = vim.uv.fs_stat(cache_path)
    local have_copy = st and vim.fn.filereadable(cache_path) == 1
    -- A future mtime (tar/unzip/rsync -t) would pass the session_start test forever and
    -- escape the age-based prune, so it counts as stale; the margin tolerates clock skew.
    local future = st and st.mtime.sec > os.time() + 60
    if st and not future and (refreshed[cache_path] or st.mtime.sec >= session_start) and have_copy then
        return cache_path
    end
    -- An unreachable container must not hide a copy that exists: stale beats the host path,
    -- which does not exist outside the container. failed_paths stays clear so a later call
    -- can refresh once the container is back.
    local function use_stale()
        if not stale_warned[path] then
            stale_warned[path] = true
            vim.notify(("container %s unreachable; showing cached copy from %s for %s")
                :format(c.name, os.date("%Y-%m-%d %H:%M", st.mtime.sec), path), vim.log.levels.WARN)
        end
        return cache_path
    end
    -- Host and pid keep concurrent fetches, even from other hosts, from sharing a tmp.
    local tmp = cache_path .. ".tmp." .. TMP_HOST .. "." .. vim.fn.getpid()
    if not physical(tmp) then
        return fail_path(path, ("container %s: not caching %s: cache path goes through a symlink"):format(c.name, path))
    end

    local now = vim.uv.now()
    local dead = dead_until[c.name]
    if have_copy and ((dead and now < dead) or (stale_retry[cache_path] or 0) > now) then
        return use_stale()
    end
    if dead and now < dead then
        if not dead_warned[c.name] then
            dead_warned[c.name] = true
            vim.notify(("container %s unresponsive; skipping fetches for %ds"):format(c.name, DEAD_MS / 1000), vim.log.levels.WARN)
        end
        return path
    end

    local ok, sys = pcall(vim.system, { c.cmd, "exec", "-i", c.name, "cat", path }, { text = true })
    if not ok then
        dead_until[c.name] = now + DEAD_MS
        dead_warned[c.name] = nil
        if have_copy then
            stale_retry[cache_path] = now + DEAD_MS
            return use_stale()
        end
        return fail_path(path, ("container %s: cannot run %s for %s: %s"):format(c.name, c.cmd, path, sys))
    end
    local res = sys:wait(2000)
    if not res or res.code ~= 0 then
        -- On timeout :wait() kills the process and yields code 124, or nil if the exit has not
        -- been reaped yet.
        local timed_out = not res or res.code == 124
        if timed_out then
            dead_until[c.name] = now + DEAD_MS
            dead_warned[c.name] = nil
        end
        if have_copy then
            stale_retry[cache_path] = now + DEAD_MS
            return use_stale()
        end
        local why = timed_out and "timed out" or vim.trim(res.stderr or "")
        return fail_path(path, ("container %s: cannot read %s: %s"):format(c.name, path, why))
    end

    local content = res.stdout or ""
    -- Written aside and renamed so other sessions only ever see a missing or a complete
    -- file (rename within one dir is atomic). A cache component that is a regular file, a
    -- read-only dir or a full disk all throw here.
    -- The tmp is created with O_EXCL after an unlink because the fetch above can block for
    -- seconds, long enough for a symlink to appear at tmp that a plain write would follow.
    -- Mode 0444: edits to a cache file never reach the container (see the readonly autocmd);
    -- rename and prune only need write permission on the directory.
    local fd
    local ok, werr = pcall(function()
        mkdir_p(vim.fs.dirname(cache_path))
        local _, uerr, uname = vim.uv.fs_unlink(tmp)
        if uerr and uname ~= "ENOENT" then error(uerr, 0) end
        local ofd, oerr = vim.uv.fs_open(tmp, "wx", tonumber("444", 8))
        if not ofd then error(oerr, 0) end
        fd = ofd
        local written, werr2 = vim.uv.fs_write(fd, content, 0)
        if not written then error(werr2, 0) end
        if written ~= #content then error("short write", 0) end
        local _, cerr = vim.uv.fs_close(fd)
        fd = nil
        if cerr then error(cerr, 0) end
        local _, rerr = vim.uv.fs_rename(tmp, cache_path)
        if rerr then error(rerr, 0) end
    end)
    if not ok then
        if fd then vim.uv.fs_close(fd) end
        vim.uv.fs_unlink(tmp)
        return fail_path(path, ("container %s: cannot write cache for %s: %s"):format(c.name, path, werr))
    end
    refreshed[cache_path] = true
    return cache_path
end

-- Kept in _G so re-sourcing wraps the original again instead of nesting wrappers. Taken
-- from the module (vim.uri_to_fname is a copy of it) because the hook below also replaces
-- the module field; the runtime original does not call that field, so the hook does not
-- recurse through it.
local uri_module = require("vim.uri")
_G._orig_uri_to_fname = _G._orig_uri_to_fname or uri_module.uri_to_fname
local orig_uri_to_fname = _G._orig_uri_to_fname

-- Jumps originate in the current buffer (the rule below handles them), but diagnostics
-- arrive regardless of focus, so they are attributed to the client that sent them. This
-- covers push (publishDiagnostics) and pull (textDocument/diagnostic, including its
-- relatedDocuments), which both reach this hook through uri_to_fname.
local converting_client
local function as_client(client_id, fn, ...)
    local prev = converting_client
    converting_client = client_id
    local res = vim.F.pack_len(pcall(fn, ...))
    converting_client = prev
    if not res[1] then error(res[2], 0) end
    return select(2, vim.F.unpack_len(res))
end

_G._orig_publish_diagnostics = _G._orig_publish_diagnostics or vim.lsp.handlers["textDocument/publishDiagnostics"]
local orig_publish_diagnostics = _G._orig_publish_diagnostics
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, ...)
    return as_client(ctx and ctx.client_id, orig_publish_diagnostics, err, result, ctx, ...)
end

-- Clients resolve this handler from vim.lsp.handlers when the response arrives, so the
-- table entry is the seam.
_G._orig_pull_diagnostics = _G._orig_pull_diagnostics or vim.lsp.handlers["textDocument/diagnostic"]
local orig_pull_diagnostics = _G._orig_pull_diagnostics
vim.lsp.handlers["textDocument/diagnostic"] = function(err, result, ctx, ...)
    return as_client(ctx and ctx.client_id, orig_pull_diagnostics, err, result, ctx, ...)
end

local function container_uri_to_fname(uri)
    local path = orig_uri_to_fname(uri)
    if not uri:match("^file://") then return path end

    -- Jumps (gd etc.) start in the current buffer, so its own client decides: a host-only
    -- buffer must not have its targets copied out of an unrelated container. Without a
    -- client in the current buffer (help, terminal, qf), fall back to the focus-independent
    -- running_container() rule.
    local c, ambiguous
    local attached = vim.lsp.get_clients({ bufnr = 0 })
    if converting_client then
        c = container_clients[converting_client]
        if not c then return path end
    elseif #attached > 0 then
        -- Lowest id wins so several container clients on one buffer map deterministically.
        table.sort(attached, function(a, b) return a.id < b.id end)
        for _, client in ipairs(attached) do
            c = container_clients[client.id]
            if c then break end
        end
        if not c then return path end
    else
        c, ambiguous = running_container()
        if ambiguous then c = container(vim.api.nvim_get_current_buf()) end
        if not c then return path end
    end

    local root = c.root or vim.fn.getcwd()
    local prefix = root:sub(-1) == "/" and root or root .. "/"
    if path == root or vim.startswith(path, prefix) then return path end

    return sync_container_file(c, path)
end
vim.uri_to_fname = container_uri_to_fname
-- vim.uri_to_bufnr (jump targets, related diagnostics, workspace edits) looks up the
-- module field uri_to_fname at call time, not vim.uri_to_fname; unpatched it adds an
-- unlisted host-path buffer next to the cache buffer. This patches a runtime module
-- field, so a runtime refactor could silently bypass it (the nvt tests check it).
uri_module.uri_to_fname = container_uri_to_fname

-- Edits to a cache file never reach the container and the next refresh discards them, so
-- such buffers are read-only. Any <root>/.cache/container/<name>/ counts, not just the roots
-- of running clients: caches of other sessions or cwds are just as disposable. BufReadPost
-- also fires for buffers loaded via vim.uri_to_bufnr + bufload (LSP jumps).
local function in_container_cache(path)
    local name = path:match("/%.cache/container/([^/]+)/")
    return name ~= nil and valid_container_name(name)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWinEnter" }, {
    group = vim.api.nvim_create_augroup("ContainerCacheReadonly", { clear = true }),
    pattern = "*/.cache/container/*",
    callback = function(args)
        if not in_container_cache(vim.api.nvim_buf_get_name(args.buf)) then return end
        vim.bo[args.buf].readonly = true
        vim.bo[args.buf].modifiable = false
    end,
})

-- A workspace edit touching a nomodifiable cache buffer would raise E21 midway and leave
-- the edit half-applied, so those changes are dropped up front. Whether a URI is a cache
-- file is whatever the uri_to_fname hook decides, so the container choice is not duplicated.
-- Kept in _G so re-sourcing wraps the original again instead of nesting wrappers.
_G._orig_apply_workspace_edit = _G._orig_apply_workspace_edit or vim.lsp.util.apply_workspace_edit
local orig_apply_workspace_edit = _G._orig_apply_workspace_edit
vim.lsp.util.apply_workspace_edit = function(workspace_edit, offset_encoding, ...)
    if type(workspace_edit) ~= "table" then
        return orig_apply_workspace_edit(workspace_edit, offset_encoding, ...)
    end
    local skipped, seen = {}, {}
    local function is_skipped(uri)
        if type(uri) ~= "string" or not uri:match("^file://") then return false end
        if not in_container_cache(vim.uri_to_fname(uri)) then return false end
        local orig_path = orig_uri_to_fname(uri)
        if not seen[orig_path] then
            seen[orig_path] = true
            table.insert(skipped, orig_path)
        end
        return true
    end

    local filtered = workspace_edit
    if workspace_edit.documentChanges then
        local kept = {}
        for _, change in ipairs(workspace_edit.documentChanges) do
            local hit
            if change.kind == "rename" then
                -- Both ends are tested without short-circuit so each skipped path is reported.
                local old_hit, new_hit = is_skipped(change.oldUri), is_skipped(change.newUri)
                hit = old_hit or new_hit
            elseif change.kind then
                hit = is_skipped(change.uri)
            else
                hit = is_skipped(change.textDocument and change.textDocument.uri)
            end
            if not hit then table.insert(kept, change) end
        end
        filtered = vim.tbl_extend("force", workspace_edit, { documentChanges = kept })
    elseif workspace_edit.changes then
        local kept = {}
        for uri, edits in pairs(workspace_edit.changes) do
            if not is_skipped(uri) then kept[uri] = edits end
        end
        filtered = vim.tbl_extend("force", workspace_edit, { changes = kept })
    end
    if #skipped > 0 then
        table.sort(skipped)
        vim.notify(("skipped edits to read-only container files: %s (edit them inside the container)")
            :format(table.concat(skipped, ", ")), vim.log.levels.WARN)
    end
    return orig_apply_workspace_edit(filtered, offset_encoding, ...)
end

-- Stale files are refetched on use, never deleted at start, so this only bounds the cache:
-- once per session and cache dir (keyed by path: the same name under another cwd is another
-- cache), files fetched over CACHE_MAX_AGE_MIN ago (reuse does not touch mtime) and tmp
-- files of dead or long-gone writers go.
-- Async find instead of a Lua walk: it never blocks startup however large the tree, and
-- without -L it neither follows symlinks (-type f skips them, symlinked dirs are not
-- entered) nor leaves the filesystem (-xdev); -delete unlinks relative to the walked dir.
-- Empty dirs are kept: removing one could race another session's mkdir-then-write.
local CACHE_MAX_AGE_MIN = 7 * 24 * 60
local TMP_MAX_AGE_MIN = 60
local pruned_caches = {}
local function prune_container_cache(name, root)
    local dir = container_cache_root(name, root)
    if pruned_caches[dir] then return end
    pruned_caches[dir] = true
    if not vim.uv.fs_lstat(dir) then return end
    -- A symlinked .cache (e.g. committed to the repo) must not redirect deletes.
    if vim.uv.fs_realpath(dir) ~= dir then
        return vim.notify(("container cache %s is reached through a symlink; not pruned"):format(dir), vim.log.levels.WARN)
    end
    local function warn(msg)
        vim.schedule(function()
            vim.notify(("container cache: cannot prune %s: %s"):format(dir, msg), vim.log.levels.WARN)
        end)
    end
    -- Another session may prune or rename concurrently: vanished files are not errors.
    -- Matches .tmp.<host>.<pid> and the pre-host .tmp.<pid>; the latter has no host, so only
    -- the age rule can remove it.
    local tmp_re = ".*\\.tmp\\.\\([A-Za-z0-9_.-]+\\.\\)?[0-9]+"
    local ok, err = pcall(vim.system, {
        "find", dir, "-xdev", "-ignore_readdir_race", "-type", "f", "(",
        "-mmin", "+" .. CACHE_MAX_AGE_MIN, "-delete",
        "-o", "-regex", tmp_re, "-mmin", "+" .. TMP_MAX_AGE_MIN, "-delete",
        "-o", "-regex", tmp_re, "-print",
        ")",
    }, { text = true }, vim.schedule_wrap(function(res)
        if res.code ~= 0 then return warn(vim.trim(res.stderr or "")) end
        -- Younger tmp files are deleted only once their writer is gone; a live writer's tmp
        -- is renamed away within the fetch timeout. Another host's pid cannot be probed.
        for f in vim.gsplit(res.stdout or "", "\n", { trimempty = true }) do
            local host, pid = f:match("%.tmp%.([%w_.-]+)%.(%d+)$")
            pid = host == TMP_HOST and tonumber(pid) or nil
            -- kill(pid, 0) fails with ESRCH only when no such process exists (EPERM: alive).
            local dead = pid and pid ~= vim.uv.os_getpid() and select(3, vim.uv.kill(pid, 0)) == "ESRCH"
            if dead and physical(f) then
                local _, uerr = vim.uv.fs_unlink(f)
                if uerr and not uerr:match("^ENOENT") then warn(uerr) end
            end
        end
    end))
    if not ok then warn(err) end
end

-- ── CONTAINER LSP ─────────────────────────────────────────────────────────────
-- Returns cmd, container_name|nil; or nil, nil, err when the buffer's container is unusable.
local function lsp_cmd(cmd, bufnr)
    local c, err = container(bufnr)
    if err then return nil, nil, err end
    if not c then return cmd, nil end

    local wrapped = { c.cmd, "exec", "-i", c.name }
    for _, arg in ipairs(cmd) do table.insert(wrapped, arg) end
    return wrapped, c.name
end

-- ── LANGUAGE SETTINGS ─────────────────────────────────────────────────────────

local function set_rg(ft, flags)
    vim.api.nvim_buf_create_user_command(0, "Rg", function(opts)
        rg_qf(opts.args, flags, (":Rg(%s) %s"):format(ft, opts.args), opts.fargs)
    end, { nargs = "+", desc = "Rg scoped to " .. ft })
    vim.keymap.set("n", "gw", function()
        rg_qf(vim.fn.expand("<cword>"), flags, (":Rg(%s) %s"):format(ft, vim.fn.expand("<cword>")))
    end, { buf = 0, desc = "Search word under cursor to quickfix (scoped)" })
    vim.keymap.set("v", "gw", visual_rg(flags, (":Rg(%s) Visual"):format(ft)),
        { buf = 0, desc = "Search selection to quickfix (scoped)" })
end

-- Per-buffer start instead of vim.lsp.enable(): enable() registers a global FileType
-- handler that reads the shared config, so a container-wrapped cmd would leak into host
-- buffers (and bypass enable_lsp=false). The shared vim.lsp.config is never mutated.
local function enable_lsp(server, bufnr)
    local config = vim.deepcopy(vim.lsp.config[server])
    if not config or type(config.cmd) ~= "table" then
        return vim.notify_once(("LSP %s: no cmd configured; not started"):format(server), vim.log.levels.WARN)
    end
    config.name = server
    local cmd, container_name, err = lsp_cmd(config.cmd, bufnr)
    if not cmd then
        return vim.notify(("LSP %s: not started: %s"):format(server, err), vim.log.levels.ERROR)
    end
    config.cmd = cmd
    if vim.fn.executable(config.cmd[1]) == 0 then
        -- Host servers are optional on this machine (go/python/java usually run in containers).
        return vim.notify_once(("LSP %s: '%s' not executable; not started"):format(server, config.cmd[1]), vim.log.levels.INFO)
    end
    local root = vim.fn.getcwd()
    if container_name then
        prune_container_cache(container_name, root)
        -- The server runs in another PID namespace; nvim's PID means nothing there.
        config.before_init = function(params) params.processId = vim.NIL end
    end
    config.root_dir = config.root_dir or vim.fs.root(bufnr, config.root_markers or {})
    local client_id = vim.lsp.start(config, {
        bufnr = bufnr,
        -- Host and container clients for the same root must stay separate processes.
        reuse_client = function(client, cfg)
            return client.name == cfg.name and not client:is_stopped()
                and client.root_dir == cfg.root_dir and vim.deep_equal(client.config.cmd, cfg.cmd)
        end,
    })
    -- cmd[1] is the container runtime (see lsp_cmd).
    if client_id and container_name then
        container_clients[client_id] = { cmd = config.cmd[1], name = container_name, root = root }
    end
end

local ft = {}

ft.c = function()
    set_rg("c/cpp", { "--type", "c", "--type", "cpp"})
end
ft.cpp = ft.c

ft.java = function()
    set_rg("java", {"--type", "java"})
end

local LSP_SERVER = {
    c = "clangd", cpp = "clangd", rust = "rust_analyzer", go = "gopls", python = "pyright", lua = "lua_ls",
}

-- Huge (often generated) files: treesitter injections, indent folding and LSP document
-- sync all scale with buffer size.
local LARGE_FILE_BYTES = 1024 * 1024

local function ensure_completion()
    -- Loading blink registers its LSP capabilities (see PLUGINS); must precede client start.
    require("blink.cmp")
end

local lang_grp = vim.api.nvim_create_augroup("LangSettings", { clear = true })

-- Before the read: indent folds are computed as the lines load, so FileType is too late.
vim.api.nvim_create_autocmd("BufReadPre", {
    group = lang_grp,
    callback = function(ev)
        if vim.fn.getfsize(ev.file) > LARGE_FILE_BYTES then vim.wo[0][0].foldmethod = "manual" end
    end,
})

-- A buffer bufload()ed while hidden (previewers) skips BufReadPre's window-local setting and
-- later gets the default indent folding when shown. Only that default is overridden, so diff
-- and explicit user fold choices survive.
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = lang_grp,
    callback = function(ev)
        if vim.wo[0][0].foldmethod == "indent" and vim.fn.getfsize(vim.api.nvim_buf_get_name(ev.buf)) > LARGE_FILE_BYTES then
            vim.wo[0][0].foldmethod = "manual"
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = lang_grp,
    callback = function(ev)
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(ev.buf) then return end
            if not vim.uri_from_bufnr(ev.buf):match("^file://") then return end

            local large = vim.fn.getfsize(vim.api.nvim_buf_get_name(ev.buf)) > LARGE_FILE_BYTES

            local lang = vim.treesitter.language.get_lang(ev.match)
            if lang and not large and vim.treesitter.language.add(lang) then
                vim.treesitter.start(ev.buf, lang)
            end

            if not vim.F.if_nil(ec(ev.buf).enable_lsp, true) then return end
            if ft[ev.match] then ft[ev.match]() end
            local server = LSP_SERVER[ev.match]
            if server and not large then
                ensure_completion()
                enable_lsp(server, ev.buf)
            end
        end)
    end
})
