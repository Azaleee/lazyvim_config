-- Chemins WSL pour Neovide --wsl
local home = vim.fn.expand("~")

-- On force DOTNET_ROOT
vim.env.DOTNET_ROOT = home .. "/.dotnet"

-- On étend le PATH pour inclure les bins user, Mason et .dotnet
vim.env.PATH = table.concat({
  home .. "/.local/bin",
  home .. "/.local/share/nvim/mason/bin",
  home .. "/.dotnet",
  vim.env.PATH, -- on garde l’ancien PATH à la fin
}, ":")

-- Force WSL paths BEFORE lazy.nvim bootstrap (pour neovide --wsl)
local data_path = vim.fn.stdpath("data")
if data_path:match("^C:") or data_path:match("^/c/") or data_path:match("^/mnt/c/") then
  local wsl_home = "/home/mosmont"
  vim.env.XDG_DATA_HOME = wsl_home .. "/.local/share"
  vim.env.XDG_STATE_HOME = wsl_home .. "/.local/state"
  vim.env.XDG_CACHE_HOME = wsl_home .. "/.cache"

  -- Override stdpath BEFORE it's used
  local original_stdpath = vim.fn.stdpath
  vim.fn.stdpath = function(what)
    local paths = {
      data = wsl_home .. "/.local/share/nvim",
      state = wsl_home .. "/.local/state/nvim",
      cache = wsl_home .. "/.cache/nvim",
      config = wsl_home .. "/.config/nvim",
    }
    return paths[what] or original_stdpath(what)
  end
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import/override with your plugins
    { import = "plugins" },
    { import = "plugins.lsp" },
    { import = "plugins.dap" },
    { import = "plugins.editor" },
    { import = "plugins.ui" },
    { import = "plugins.navigation" },
    { import = "plugins.git" },
    { import = "plugins.extras" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
