return {
  { "ibhagwan/fzf-lua", enabled = false },
  { "folke/flash.nvim", enabled = false },
  { "ggandor/leap.nvim", enabled = false },
  { "folke/trouble.nvim", keys = { { "<leader>d", false } } },

  -- lua/plugins/noice.lua
  {
    {
      "folke/noice.nvim",
      opts = function(_, opts)
        opts.lsp = opts.lsp or {}
        opts.lsp.progress = opts.lsp.progress or {}
        opts.lsp.progress.enabled = false -- on coupe le LSP progress
      end,
    },
  },
}
