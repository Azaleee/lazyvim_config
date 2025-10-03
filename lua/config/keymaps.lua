-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Float ToggleTerm on Ctrl-/
do
  local ok, tt = pcall(require, "toggleterm.terminal")
  if ok then
    local Terminal = tt.Terminal
    local float_term = Terminal:new({ id = 99, direction = "float", hidden = true })
    vim.keymap.set({ "n", "t" }, "<C-/>", function()
      float_term:toggle()
    end, { desc = "Float Terminal (ToggleTerm #99)", silent = true, noremap = true })

    -- Astuce: sur beaucoup de claviers, <C-/> == <C-_>
    vim.keymap.set({ "n", "t" }, "<C-_>", function()
      float_term:toggle()
    end, { desc = "Float Terminal (ToggleTerm #99)", silent = true, noremap = true })
  end
end

vim.keymap.set("n", "<leader>d", function()
  vim.diagnostic.open_float(nil, { focus = false, border = "rounded" })
end, { desc = "Show line diagnostics" })
