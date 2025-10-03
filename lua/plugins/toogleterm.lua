return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    local toggleterm = require("toggleterm")

    toggleterm.setup({
      direction = "float",
      float_opts = { border = "curved" },
      start_in_insert = true,
    })

    -- Terminal flottant dédié (toujours ID 99)
    local Terminal = require("toggleterm.terminal").Terminal
    local float_term = Terminal:new({ direction = "float", hidden = true, id = 99 })

    -- Mapping Ctrl+/ pour ouvrir/fermer
    vim.keymap.set({ "n", "t" }, "<C-/>", function()
      float_term:toggle()
    end, { desc = "ToggleTerm Float (99)", silent = true, noremap = true })
  end,
}
