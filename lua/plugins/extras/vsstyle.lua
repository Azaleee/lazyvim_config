-- File: lua/plugins/ide_vsstyle.lua
-- Pack "VS-like" : refs au-dessus des fonctions + menu déroulant + peek + breadcrumbs + lightbulb
return {

  -- 1) Affiche "N references" / "N implementations" au-dessus des fonctions
  {
    "VidocqH/lsp-lens.nvim",
    event = "LspAttach",
    config = function()
      require("lsp-lens").setup({
        enable = true,
        include_declaration = false,
        sections = { definition = false, references = true, implementation = true },
      })
      -- Style (optionnel)
      vim.api.nvim_set_hl(0, "LspLens", { fg = "#8a8f98", italic = true })
    end,
  },

  -- 2) Lspsaga : peek + finder "VS-like" + (bonus) codelens refresh intégré ici
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("lspsaga").setup({
        code_lens = { enable = true },
        symbol_in_winbar = { enable = true, separator = "  ", hide_keyword = true },
        ui = { border = "rounded" },
        lightbulb = {
          enable = false,
          sign = true,
          virtual_text = false,
          sign_priority = 30,
        },
      })

      -- Keymaps "VS-like"
      vim.keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<CR>", { desc = "Peek definition" })
      vim.keymap.set("n", "gD", "<cmd>Lspsaga peek_type_definition<CR>", { desc = "Peek type def" })
      vim.keymap.set("n", "gR", "<cmd>Lspsaga finder ref<CR>", { desc = "Peek references (finder)" })
      vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc = "Code Action" })
      vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover (fancy)" })
      vim.keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", { desc = "Rename symbol" })

      -- Raccourcis CodeLens natifs (au cas où ton serveur les expose)
      vim.keymap.set("n", "<leader>cl", function()
        vim.lsp.codelens.refresh()
      end, { desc = "CodeLens: refresh" })
      vim.keymap.set("n", "<leader>cr", function()
        vim.lsp.codelens.run()
      end, { desc = "CodeLens: run under cursor" })

      -- Auto-refresh CodeLens quand le serveur les supporte
      vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
        callback = function()
          for _, c in ipairs(vim.lsp.get_clients({ buf = 0 })) do
            if c.server_capabilities and c.server_capabilities.codeLensProvider then
              pcall(vim.lsp.codelens.refresh)
              break
            end
          end
        end,
      })

      -- Navigation LSP "VS"
      vim.keymap.set("n", "gT", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
      vim.keymap.set("n", "<leader>fm", function()
        vim.lsp.buf.format({ async = true })
      end, { desc = "Format buffer" })
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    event = "LspAttach",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local tb = require("telescope.builtin")
      require("telescope").setup({
        pickers = {
          lsp_references = { theme = "dropdown", previewer = false },
          lsp_definitions = { theme = "dropdown", previewer = false },
          lsp_implementations = { theme = "dropdown", previewer = false },
        },
      })
      vim.keymap.set("n", "gr", function()
        tb.lsp_references()
      end, { desc = "References (dropdown)" })
      vim.keymap.set("n", "gD", function()
        tb.lsp_definitions()
      end, { desc = "Definitions (dropdown)" })
      vim.keymap.set("n", "gI", function()
        tb.lsp_implementations()
      end, { desc = "Implementations (dropdown)" })
    end,
  },

  -- 4) Trouble : panneau type "Find all references" lisible
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = {},
    keys = {
      { "<leader>rr", "<cmd>Trouble lsp_references toggle<cr>", desc = "References (Trouble panel)" },
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    },
  },

  -- 5) Lightbulb : ampoule quand une action est dispo
  {
    "aznhe21/actions-preview.nvim",
    event = "LspAttach",
    config = function()
      require("actions-preview").setup({
        -- utilise Telescope si présent, sinon une liste simple
        telescope = { sorting_strategy = "ascending", layout_strategy = "vertical" },
      })
      -- Alt+Entrée comme sur VS pour ouvrir le menu d'actions
      vim.keymap.set(
        { "n", "v" },
        "<A-CR>",
        require("actions-preview").code_actions,
        { desc = "Code actions (preview)" }
      )
    end,
  },

  -- 6) Breadcrumbs (contexte en haut de la fenêtre)
  {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    event = "LspAttach",
    dependencies = { "SmiteshP/nvim-navic", "nvim-tree/nvim-web-devicons" },
    opts = {
      show_dirname = false,
      show_basename = true,
      create_autocmd = true,
      theme = { normal = { bg = "NONE" } },
    },
  },
}
