return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("diffview").setup({
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
    })

    -- Raccourcis utiles
    vim.keymap.set("n", "<leader>gd", ":DiffviewOpen<CR>", { desc = "Open Git Diff" })
    vim.keymap.set("n", "<leader>gq", ":DiffviewClose<CR>", { desc = "Close Diffview" })
    vim.keymap.set("n", "<leader>gh", ":DiffviewFileHistory %<CR>", { desc = "File history" })
  end
}
