return {
  -- Plugin principal Copilot
  {
    "github/copilot.vim",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_filetypes = {
        ["*"] = true,
        markdown = false,
        text = false,
      }
      vim.keymap.set("i", "<C-;>", 'copilot#Accept("<CR>")', {
        expr = true, replace_keycodes = false, desc = "Accept Copilot suggestion",
      })
    end,
  },

  -- CopilotChat
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      -- 🔑 le point important
      context = "workspace",  -- "buffers" | "visible" | "workspace"
      debug = false,
      window = {
        layout = "float",
        width = 0.7,
        height = 0.7,
        border = "rounded",
      },
    },
    keys = {
      { "<leader>cc", "<cmd>CopilotChat<CR>",          desc = "Open Copilot Chat" },
      { "<leader>cq", "<cmd>CopilotChatToggle<CR>",    desc = "Toggle Copilot Chat" },
      { "<leader>ce", "<cmd>CopilotChatExplain<CR>",   desc = "Explain code under cursor" },
      { "<leader>cf", "<cmd>CopilotChatFix<CR>",       desc = "Fix problem in code" },

      -- 🔁 Raccourcis pour changer de contexte à la volée (optionnel)
      { "<leader>cW", function()
          require("CopilotChat.config").options.context = "workspace"
          vim.notify("CopilotChat context: workspace")
        end, desc = "CopilotChat: use workspace context" },
      { "<leader>cB", function()
          require("CopilotChat.config").options.context = "buffers"
          vim.notify("CopilotChat context: buffers (open buffers only)")
        end, desc = "CopilotChat: use buffers context" },
      { "<leader>cV", function()
          require("CopilotChat.config").options.context = "visible"
          vim.notify("CopilotChat context: visible windows only")
        end, desc = "CopilotChat: use visible context" },
    },

    -- (facultatif) crée des :commands conviviales
    config = function(_, opts)
      require("CopilotChat").setup(opts)

      vim.api.nvim_create_user_command("CopilotChatContextWorkspace", function()
        require("CopilotChat.config").options.context = "workspace"
        print("CopilotChat context: workspace")
      end, {})

      vim.api.nvim_create_user_command("CopilotChatContextBuffers", function()
        require("CopilotChat.config").options.context = "buffers"
        print("CopilotChat context: buffers")
      end, {})

      vim.api.nvim_create_user_command("CopilotChatContextVisible", function()
        require("CopilotChat.config").options.context = "visible"
        print("CopilotChat context: visible")
      end, {})

      -- Pour vérifier le contexte courant rapidement
      vim.api.nvim_create_user_command("CopilotChatContext", function()
        print("CopilotChat context: " .. tostring(require("CopilotChat.config").options.context))
      end, {})
    end,
  },
}
