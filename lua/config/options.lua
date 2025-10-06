-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
vim.g.lazyvim_python_ruff = "ruff"

vim.o.guifont = "ProFont IIx Nerd Font Mono:h11"

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    vim.opt.indentexpr = ""
  end,
})

-- Sécurise le tout premier buffer: (re)détecte filetype & active syntax si besoin
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    if vim.bo[args.buf].filetype == "" or vim.bo[args.buf].filetype == "text" then
      vim.cmd("filetype detect")
    end
    if not vim.fn.exists("g:syntax_on") or vim.fn.exists("g:syntax_on") == 0 then
      vim.cmd("syntax enable")
    end
  end,
})

-- Optionnel : animation du curseur plus fluide
vim.g.neovide_cursor_vfx_mode = "railgun"

if vim.g.neovide then
  -- Opacité de la fenêtre
  vim.g.neovide_opacity = 0.95
  vim.g.neovide_normal_opacity = 1.0

  -- Quantité de flou pour les fenêtres flottantes
  vim.g.neovide_floating_blur_amount_x = 12.0
  vim.g.neovide_floating_blur_amount_y = 12.0
end

-- Truecolor activé
vim.o.termguicolors = true

-- Forcer les flottants transparents pour laisser passer le blur
local function clear_float_bg()
  vim.cmd("hi NormalFloat guibg=NONE ctermbg=NONE")
  vim.cmd("hi FloatBorder guibg=NONE ctermbg=NONE")
end
clear_float_bg()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("NeovideFloatBG", { clear = true }),
  callback = clear_float_bg,
})

-- Exemple : C# = 4 espaces
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "cs", "csharp" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

-- Exemple : Lua = 2 espaces
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

vim.g.copilot_node_command = "/home/mosmont/.nvm/versions/node/v22.20.0/bin/node"
