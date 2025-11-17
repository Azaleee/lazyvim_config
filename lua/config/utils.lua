-- lua/config/utils.lua
local M = {}

-- Remet une largeur fixe au Snacks explorer (liste)
function M.resize_snacks_explorer()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })

    -- Ici on cible la liste de Snacks (explorer = picker sidebar)
    if ft == "snacks_picker_list" then
      -- Largeur fixe en colonnes
      -- adapte 35 / 40 / 45 selon ce qui te plaît
      pcall(vim.api.nvim_win_set_width, win, 40)
    end
  end
end

return M
