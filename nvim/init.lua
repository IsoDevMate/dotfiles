-- =============================================
-- NEOVIM CONFIGURATION
-- Leader key
-- =============================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- =============================================
-- OPTIONS
-- =============================================
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true
opt.wrap = false
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.clipboard = "unnamedplus"
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.completeopt = { "menuone", "noselect", "noinsert" }
opt.shortmess:append("c")
opt.splitright = true
opt.splitbelow = true
opt.updatetime = 50
opt.timeoutlen = 300
opt.mouse = "a"

-- =============================================
-- PLUGIN MANAGER (LAZY.NVIM)
-- =============================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================
-- PLUGINS
-- =============================================
require("lazy").setup({

  -- Neodev (Neovim lua API completions)
  {
    "folke/neodev.nvim",
    config = function() require("neodev").setup({}) end,
  },

  -- Colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "macchiato",
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          telescope = true,
          treesitter = true,
          harpoon = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 35, side = "left" },
        renderer = {
          group_empty = true,
          highlight_git = true,
          icons = { show = { git = true, folder = true, file = true, folder_arrow = true } },
        },
        filters = {
          dotfiles = false,
          custom = { ".git", "node_modules", ".cache" },
        },
        git = { enable = true, ignore = false },
      })
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.4",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local actions = require("telescope.actions")
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
          },
        },
      })
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "c", "lua", "vim", "vimdoc", "query",
          "javascript", "typescript", "tsx", "json",
          "html", "css", "python", "java", "dart",
          "go", "rust", "markdown", "bash", "yaml",
          "toml", "dockerfile", "gitignore",
        },
        sync_install = false,
        auto_install = true,
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
      })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "j-hui/fidget.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls", "ts_ls", "html", "cssls",
          "tailwindcss", "pyright", "gopls",
          "rust_analyzer", "clangd",
        },
      })

      -- Shared capabilities for nvim-cmp (applies to all servers)
      local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
      vim.lsp.config("*", { capabilities = lsp_capabilities })

      -- Per-server settings (mason-lspconfig auto-enables installed servers)
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })

      -- dartls is usually from the Dart SDK, not Mason
      vim.lsp.config("dartls", {
        cmd = { "dart", "language-server", "--protocol=lsp" },
      })
      vim.lsp.enable("dartls")

      -- Keymaps + format-on-save when an LSP attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(event)
          local opts = { buffer = event.buf, remap = false }
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = false })
          end, opts)
          vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, opts)
          vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, opts)
          vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, opts)

          if client and client:supports_method("textDocument/formatting") then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = event.buf,
              callback = function()
                vim.lsp.buf.format({ async = false, bufnr = event.buf })
              end,
            })
          end
        end,
      })

      require("fidget").setup()
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        completion = { completeopt = "menu,menuone,preview,noselect" },
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- Harpoon
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup({
        settings = {
          save_on_toggle = false,
          sync_on_ui_close = false,
          save_on_change = true,
          excluded_filetypes = { "harpoon", "alpha", "dashboard", "gitcommit" },
          mark_branch = false,
          key = function() return vim.loop.cwd() end,
        },
      })
    end,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
      })
    end,
  },

  -- Terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then return 12
          elseif term.direction == "vertical" then return math.ceil(vim.o.columns * 0.3)
          end
        end,
        open_mapping = [[<c-\>]],
        direction = "horizontal",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          width = math.ceil(vim.o.columns * 0.6),
          height = math.ceil(vim.o.lines * 0.6),
        },
      })
    end,
  },

  -- Surround
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function() require("nvim-surround").setup({}) end,
  },

  -- Comments
  {
    "numToStr/Comment.nvim",
    config = function() require("Comment").setup() end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function() require("nvim-autopairs").setup({}) end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function() require("ibl").setup() end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto", -- follows colorscheme (catppuccin)
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },

  -- Zen mode
  {
    "folke/zen-mode.nvim",
    config = function() require("zen-mode").setup() end,
  },
})

-- =============================================
-- KEYMAPS
-- =============================================
local map = vim.keymap.set

-- Escape
map("i", "jk", "<ESC>", { desc = "Exit insert mode" })

-- Clear search highlight
map("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- Save / Quit
map("n", "<leader>w", ":w<CR>", { desc = "Save file" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })
map("n", "<leader>qa", ":qa<CR>", { desc = "Quit all" })

-- Increment/decrement
map("n", "<leader>+", "<C-a>", { desc = "Increment number" })
map("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Window splits
map("n", "<leader>sv", "<C-w>v", { desc = "Split vertically" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split horizontally" })
map("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- Resize splits
map("n", "<leader>t+", "<cmd>resize +3<CR>", { desc = "Increase height" })
map("n", "<leader>t-", "<cmd>resize -3<CR>", { desc = "Decrease height" })
map("n", "<leader>t>", "<cmd>vertical resize +10<CR>", { desc = "Increase width" })
map("n", "<leader>t<", "<cmd>vertical resize -10<CR>", { desc = "Decrease width" })

-- Tabs
map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Next tab" })
map("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Previous tab" })

-- Buffers
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bl", ":ls<CR>", { desc = "List buffers" })

-- File explorer
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
map("n", "<leader>o", "<cmd>NvimTreeFocus<CR>", { desc = "Focus file explorer" })
map("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Find current file in tree" })
map("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" })
map("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" })

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" })
map("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Grep word under cursor" })

-- Harpoon
vim.schedule(function()
  local harpoon = require("harpoon")
  map("n", "<leader>a", function() harpoon:list():add() end, { desc = "Add file to harpoon" })
  map("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon menu" })
  map("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Harpoon file 1" })
  map("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Harpoon file 2" })
  map("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Harpoon file 3" })
  map("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Harpoon file 4" })
  map("n", "<C-S-P>", function() harpoon:list():prev() end, { desc = "Harpoon prev" })
  map("n", "<C-S-N>", function() harpoon:list():next() end, { desc = "Harpoon next" })
end)

-- Terminal
map("n", "<leader>tt", "<cmd>ToggleTerm size=12 direction=horizontal<CR>", { desc = "Horizontal terminal" })
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", { desc = "Floating terminal" })
map("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>", { desc = "Vertical terminal" })
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Terminal → left window" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Terminal → bottom window" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Terminal → top window" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Terminal → right window" })

-- Scrolling (centered)
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "n", "nzzzv", { desc = "Next search result centered" })
map("n", "N", "Nzzzv", { desc = "Previous search result centered" })

-- Move lines in visual mode (J/K)
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Move lines with Alt+↑/↓ (Cursor / VS Code style)
map("n", "<A-Up>", ":m .-2<CR>==", { desc = "Move line up" })
map("n", "<A-Down>", ":m .+1<CR>==", { desc = "Move line down" })
map("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", { desc = "Move line up" })
map("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down" })
map("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })


-- Stay in indent mode
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Duplicate line
map("n", "<leader>dd", "yyp", { desc = "Duplicate line down" })
map("v", "<leader>dd", "y'>p", { desc = "Duplicate selection down" })

-- C compile & run
map("n", "<leader>cr", function()
  local filename = vim.fn.expand("%:r")
  vim.cmd("split | terminal gcc % -o " .. filename .. " && ./" .. filename)
end, { desc = "Compile & run C file" })

-- =============================================
-- AUTOCOMMANDS
-- =============================================
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 100 })
  end,
})

-- Close utility windows with q
autocmd("FileType", {
  pattern = { "qf", "help", "man", "notify", "lspinfo", "startuptime", "PlenaryTestPopup" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Auto resize splits on window resize
autocmd("VimResized", {
  pattern = "*",
  command = "tabdo wincmd =",
})

-- =============================================
-- DIAGNOSTICS
-- =============================================
vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = { border = "rounded", source = "always", header = "", prefix = "" },
})

local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end
