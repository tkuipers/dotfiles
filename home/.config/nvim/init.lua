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
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { side = "left", width = 30 },
        filters = { dotfiles = false },
      })
    end,
  },
  { "DreamMaoMao/yazi.nvim", dependencies = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"}},
  {
    "coder/claudecode.nvim",
    config = function()
      require("claudecode").setup()
    end,
  },
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

-- A colored background would paint over the terminal's transparency.
-- Colours come from theme-apply, which signals running copies to follow.
local function apply_theme()
  local palette = vim.fn.expand("~/.local/state/theme/nvim/palette.lua")
  require("catppuccin").setup({
    flavour = "mocha",
    transparent_background = true,
    float = { transparent = true },
    color_overrides = { mocha = vim.uv.fs_stat(palette) and dofile(palette) or {} },
  })
  vim.cmd.colorscheme "catppuccin-mocha"
end
apply_theme()
vim.api.nvim_create_autocmd("Signal", { pattern = "SIGUSR1", callback = apply_theme })

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
vim.api.nvim_set_keymap("n", "<C-e>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

-- Misc settings
vim.wo.number = true

vim.opt.mouse=""



