local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }},
  { "github/copilot.vim" },
  { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },
  { "preservim/nerdtree" },
})

vim.cmd.colorscheme "catppuccin-frappe"

-- Configure lualine
require('lualine').setup {
  options = {
    theme = 'catppuccin',
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
}

-- Non-macOS key mappings
vim.api.nvim_set_keymap("i", "<C-i>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
vim.api.nvim_set_keymap("n", "<C-n>", ":NERDTreeToggle<CR>", { noremap = true, silent = true })

-- Misc settings
vim.wo.number = true

vim.g.NERDTreeShowHidden = 1



