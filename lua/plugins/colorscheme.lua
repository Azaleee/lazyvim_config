return {
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false, -- charge immédiatement
    priority = 1000, -- s'assure qu'il se charge avant les autres
    config = function()
      require("cyberdream").setup({
        transparent = true, -- option : transparent background
        italic_comments = true,
        hide_fillchars = true,
        borderless_telescope = false,
        terminal_colors = true,
      })
      vim.cmd.colorscheme("cyberdream")
    end,
  },
}
