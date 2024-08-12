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
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }},
  { "github/copilot.vim" },
  { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },
  { "preservim/nerdtree" },
  { "DreamMaoMao/yazi.nvim", dependencies = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"}},
  { "kdheepak/lazygit.nvim", dependencies = {"nvim-lua/plenary.nvim"}, cmd = {"LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile"}},
  {
  "lervag/vimtex",
  lazy = false,     -- we don't want to lazy load VimTeX
  -- tag = "v2.15", -- uncomment to pin to a specific release
  init = function()
    -- VimTeX configuration goes here, e.g.
    vim.g.vimtex_view_method = "zathura"
  end
  },
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
vim.api.nvim_set_keymap("n", "<C-n>", ":Yazi<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-b>", ":LazyGit<CR>", { noremap = true, silent = true })

-- Misc settings
vim.wo.number = true

vim.g.NERDTreeShowHidden = 1
vim.opt.mouse=""



