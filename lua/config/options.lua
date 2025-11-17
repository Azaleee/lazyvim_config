-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
vim.g.lazyvim_python_ruff = "ruff"

vim.g.mapleader = " " -- Espace comme leader
vim.g.maplocalleader = " "

vim.o.guifont = "Terminess Nerd Font Mono:h15"

vim.g.neovide_cursor_vfx_mode = "pixiedust"

if vim.g.neovide then
  -- Opacité de la fenêtre
  vim.g.neovide_opacity = 1
  vim.g.neovide_normal_opacity = 1.0

  -- Quantité de flou pour les fenêtres flottantes
  vim.g.neovide_floating_blur_amount_x = 12.0
  vim.g.neovide_floating_blur_amount_y = 12.0
end

vim.o.termguicolors = true

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99

vim.g.snacks_explorer_disable = true
