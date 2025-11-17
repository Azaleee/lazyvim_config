-- lua/plugins/lsp.lua
return {
  -- Mason

  {
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    },
  },

  -- mason-lspconfig : on fait TOUT ici (ensure_installed + handlers)
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig", "hrsh7th/cmp-nvim-lsp" },
    lazy = false,
    config = function()
      local mason_lspconfig = require("mason-lspconfig")
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      mason_lspconfig.setup({
        ensure_installed = {
          "lua_ls",
          "pylsp",
          "jsonls",
          "sqlls",
          "terraformls",
          "yamlls",
          "bashls",
          "dockerls",
          "docker_compose_language_service",
          "html",
          "clangd",
        },
        automatic_installation = true,

        handlers = {
          function(server_name)
            local config = {
              capabilities = capabilities,
            }

            ------------------------------------------------------------------
            -- Lua (lua_ls)
            ------------------------------------------------------------------
            if server_name == "lua_ls" then
              config.settings = {
                Lua = {
                  diagnostics = { globals = { "vim" } },
                  workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                    checkThirdParty = false,
                  },
                  completion = { callSnippet = "Replace" },
                  format = { enable = false },
                },
              }
            end

            ------------------------------------------------------------------
            -- Python (pylsp)
            ------------------------------------------------------------------
            if server_name == "pylsp" then
              config.settings = {
                pylsp = {
                  plugins = {
                    pyflakes = { enabled = false },
                    pycodestyle = { enabled = false },
                    autopep8 = { enabled = false },
                    yapf = { enabled = false },
                    mccabe = { enabled = false },
                    pylsp_mypy = { enabled = false },
                    pylsp_black = { enabled = false },
                    pylsp_isort = { enabled = false },
                  },
                },
              }
            end

            ------------------------------------------------------------------
            -- HTML
            ------------------------------------------------------------------
            if server_name == "html" then
              config.filetypes = { "html", "twig", "hbs" }
            end

            -- setup final
            lspconfig[server_name].setup(config)
          end,
        },
      })
    end,
  },

  -- nvim-lspconfig : ici on garde juste les mappings / LspAttach / highlights
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      { "j-hui/fidget.nvim", opts = {} },
    },
    config = function()
      -- Mappings LSP
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
          map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
          map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
          map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
          map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
          map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
          map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
          map("K", vim.lsp.buf.hover, "Hover Documentation")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
          map("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
          map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
          map("<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, "[W]orkspace [L]ist Folders")

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- Document highlight
          if client and client.server_capabilities.documentHighlightProvider then
            local hl = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = hl,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = hl,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- Inlay hints
          if client and client.server_capabilities.inlayHintProvider then
            map("<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, "[T]oggle Inlay [H]ints")
          end

          -- indentation C#
          if vim.bo[event.buf].filetype == "cs" then
            vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter.indent'.get_indent()"
          end
        end,
      })
    end,
  },
}
