-- bootstrap lazy.nvim, LazyVim and your plugins
-- (WSL path detection is now in lua/config/lazy.lua to run before lazy.nvim bootstrap)
require("config.lazy")
vim.g.copilot_node_command = "/home/mosmont/.nvm/versions/node/v22.20.0/bin/node"
