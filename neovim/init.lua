-- Leader key
vim.g.mapleader = " "

-- Clipboard keybindings: Ctrl+C/V/X/A for normal editor behavior using system clipboard
-- Yank/delete commands still use vim's internal buffer (no auto-sync)
vim.keymap.set({ "n", "v" }, "<C-c>", '"+y', { desc = "Copy to clipboard" })
vim.keymap.set({ "n", "v" }, "<C-x>", '"+d', { desc = "Cut to clipboard" })
vim.keymap.set({ "n", "v" }, "<C-v>", '"+p', { desc = "Paste from clipboard" })
vim.keymap.set("i", "<C-v>", '<C-r>+', { desc = "Paste from clipboard in insert mode" })
vim.keymap.set("n", "<C-a>", 'ggVG', { desc = "Select all" })
vim.keymap.set("n", "<Space>h", ':noh<CR>', { desc = "Clear search highlighting" })

-- Display settings
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.ruler = true

-- Search settings
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Default indentation settings (fallback when file detection fails)
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- Lazy plugin manager setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = { "neovim-treesitter/treesitter-parser-registry" },
    lazy = false,
    build = ":TSUpdate",
    config = function()

      require('nvim-treesitter').install { 'bash', 'c_sharp', 'json', 'lua', 'markdown', 'markdown_inline', 'powershell', 'python', 'typescript', 'xml', 'yaml' }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'bash', 'c_sharp', 'json', 'lua', 'markdown', 'markdown_inline', 'powershell', 'python', 'typescript', 'xml', 'yaml' },
        callback = function()
          vim.treesitter.start()
          vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          vim.wo.foldmethod = 'expr'
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    "tpope/vim-sleuth",
    -- Sleuth auto-detects tabwidth, shiftwidth, and expandtab per file
  },
})
