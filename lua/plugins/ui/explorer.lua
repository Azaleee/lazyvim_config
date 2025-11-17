return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    explorer = {
      enabled = true,
    },
    picker = {
      enabled = true,
      layouts = {
        sidebar = {
          layout = {
            width = 0.22,
            min_width = 30,
          },
        },
      },
    },
  },
}
