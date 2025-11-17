-- Force WSL paths for data storage
if vim.fn.has("wsl") == 1 then
  local wsl_home = "/home/mosmont"
  vim.env.XDG_DATA_HOME = wsl_home .. "/.local/share"
  vim.env.XDG_STATE_HOME = wsl_home .. "/.local/state"
  vim.env.XDG_CACHE_HOME = wsl_home .. "/.cache"
end

-- Load main init
require("config.lazy")
vim.g.copilot_node_command = "/home/mosmont/.nvm/versions/node/v22.20.0/bin/node"
