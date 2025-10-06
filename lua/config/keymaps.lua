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

-- For conciseness
local opts = { noremap = true, silent = true }

-- delete single character without copying into register
vim.keymap.set("n", "x", '"_x', opts)

-- Increment/decrement numbers
vim.keymap.set("n", "<leader>+", "<C-a>", opts) -- increment
vim.keymap.set("n", "<leader>-", "<C-x>", opts) -- decrement

-- Toggle line wrapping
vim.keymap.set("n", "<leader>lw", "<cmd>set wrap!<CR>", opts)

-- Replace word under cursor
vim.keymap.set("n", "<leader>j", "*``cgn", opts)

if vim.g.neovide then
  -- Toggle plein écran avec Alt+Entrée
  vim.keymap.set("n", "<A-CR>", function()
    vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
  end, { desc = "Toggle fullscreen in Neovide" })
end

-- Indentation intuitive en mode visuel
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent selection" })
vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Unindent selection" })

-- === Déplacement de lignes / blocs ===
-- Mode normal
vim.keymap.set("n", "<A-Up>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("n", "<A-Down>", ":m .+1<CR>==", { desc = "Move line down" })

-- Mode visuel
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "Move block up" })
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "Move block down" })

-- Naviguer entre les buffers ouverts
vim.keymap.set("n", "<C-,>", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<C-.>", ":bnext<CR>", { desc = "Next buffer" })
