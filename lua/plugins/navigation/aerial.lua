return {
  "stevearc/aerial.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  config = function()
    require("aerial").setup({
      backends = { "treesitter", "lsp", "markdown", "man" },
      layout = { min_width = 28 },
      show_guides = true,
    })

    -- Ouvre/ferme le panneau avec <leader>a
    vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>", { desc = "Toggle Aerial outline" })
  end,
}
