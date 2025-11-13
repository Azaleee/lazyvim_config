-- return {
--   {
--     "scottmckendry/cyberdream.nvim",
--     lazy = false, -- charge immédiatement
--     priority = 1000, -- s'assure qu'il se charge avant les autres
--     config = function()
--       require("cyberdream").setup({
--         transparent = true, -- option : transparent background
--         italic_comments = true,
--         hide_fillchars = true,
--         borderless_telescope = false,
--         terminal_colors = true,
--       })
--       vim.cmd.colorscheme("cyberdream")
--     end,
--   },
-- }
-- lua/plugins/colorscheme.lua
-- lua/plugins/colorscheme.lua
return {
  "AlexvZyl/nordic.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.opt.termguicolors = true

    -- Config Nordic (valeurs par défaut + ajustements utiles)
    require("nordic").setup({
      bold_keywords = false,
      italic_comments = true,
      transparent = { bg = false, float = false },
      reduced_blue = true,
      bright_border = false,
      swap_backgrounds = false,
      cursorline = {
        bold = false,
        bold_number = true,
        theme = "dark", -- "dark" | "light"
        blend = 0.85,
      },
      telescope = { style = "flat" },
      noice = { style = "classic" },
      ts_context = { dark_background = true },
      -- Tu pourrais aussi faire tes overrides dans on_highlight, mais on reste
      -- sur des overrides post-colorscheme pour garder la même logique.
      -- on_highlight = function(hl, p) ... end,
    })

    -- Charger le thème
    require("nordic").load()

    -- === Highlights robustes pour CodeLens / Lens / InlayHints ===
    local function set_lens_hl()
      -- Teintes lisibles dans l'esprit Nord/Nordic
      local lens_fg = "#A3BE8C" -- vert doux
      vim.api.nvim_set_hl(0, "LspCodeLens",          { fg = lens_fg, italic = true })
      vim.api.nvim_set_hl(0, "LspCodeLensSeparator", { fg = "#4C566A" })

      -- Groupes du plugin lsp-lens.nvim (silencieux si plugin absent)
      vim.api.nvim_set_hl(0, "LspLens",       { fg = lens_fg, italic = true })
      vim.api.nvim_set_hl(0, "LspLensText",   { fg = lens_fg, italic = true })
      vim.api.nvim_set_hl(0, "LspLensSymbol", { fg = lens_fg })

      -- Inlay hints (selon ta version de Neovim)
      pcall(vim.api.nvim_set_hl, 0, "LspInlayHint", { fg = "#81A1C1", bg = "NONE", italic = true })
    end
    set_lens_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = set_lens_hl,
      desc = "Réappliquer les couleurs CodeLens/Lens après reload",
    })

    -- === Commentaires plus visibles (Vim, Treesitter, LSP sémantique) ===
    local function override_highlights()
      local comment_fg = "#88C0D0"
      vim.api.nvim_set_hl(0, "Comment",           { fg = comment_fg, italic = true })
      vim.api.nvim_set_hl(0, "@comment",          { fg = comment_fg, italic = true })
      vim.api.nvim_set_hl(0, "@lsp.type.comment", { fg = comment_fg, italic = true })
    end
    override_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = override_highlights,
      desc = "Fix comment color after any colorscheme reload",
    })
  end,
}

