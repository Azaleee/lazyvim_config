return {
  -- Plugin principal Copilot
  {
    "github/copilot.vim",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      -- Active Copilot automatiquement
      vim.g.copilot_no_tab_map = true  -- pour éviter de casser ton <Tab> de nvim-cmp
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_filetypes = {
        ["*"] = true,      -- active partout
        markdown = false,  -- désactive dans les fichiers markdown
        text = false,
      }

      -- Map de validation custom (ex: Ctrl+Space ou Ctrl+l)
      vim.keymap.set("i", "<C-l>", 'copilot#Accept("<CR>")', {
        expr = true,
        replace_keycodes = false,
        desc = "Accept Copilot suggestion",
      })
    end,
  },
{
  "CopilotC-Nvim/CopilotChat.nvim",
  branch = "canary",
  dependencies = {
    { "github/copilot.vim" },
    { "nvim-lua/plenary.nvim" },
  },
  opts = {
    debug = false,
    window = {
      layout = "float",
      width = 0.7,
      height = 0.7,
      border = "rounded",
    },
  },
  keys = {
    { "<leader>cc", "<cmd>CopilotChat<CR>", desc = "Open Copilot Chat" },
    { "<leader>cq", "<cmd>CopilotChatToggle<CR>", desc = "Toggle Copilot Chat" },
    { "<leader>ce", "<cmd>CopilotChatExplain<CR>", desc = "Explain code under cursor" },
    { "<leader>cf", "<cmd>CopilotChatFix<CR>",     desc = "Fix problem in code" },
  },
}
}
