-- lua/plugins/lsp.lua
return {
  ---------------------------------------------------------------------------
  -- Mason: on laisse Lazy gérer setup(); on NE rappelle PAS require("mason").setup()
  ---------------------------------------------------------------------------
  {
    "mason-org/mason.nvim",
    -- pas de config=true ! (c’était ça qui faisait un 2e setup + registres dupliqués)
    opts = function(_, opts)
      -- Une seule source de registre = plus d’avertissements "duplicate registry entry"
      opts = opts or {}
      -- opts.PATH = "prepend" -- (optionnel)
      return opts
    end,
  },

  ---------------------------------------------------------------------------
  -- mason-lspconfig: on demande l’install par NOMS lspconfig (pas les noms Mason)
  ---------------------------------------------------------------------------
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = function(_, opts)
      opts = opts or {}
      opts.ensure_installed = vim.tbl_deep_extend("force", opts.ensure_installed or {}, {
        "lua_ls",
        "pylsp",
        "ruff", -- mappe vers le package Mason "ruff-lsp"
        "jsonls",
        "sqlls",
        "terraformls",
        "yamlls",
        "bashls",
        "dockerls",
        "docker_compose_language_service",
        "html",
        "clangd",
      })
      return opts
    end,
  },

  ---------------------------------------------------------------------------
  -- mason-tool-installer: outils/serveurs par NOMS Mason
  ---------------------------------------------------------------------------
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim", "mason-org/mason-lspconfig.nvim" },
    opts = {
      ensure_installed = {
        -- LSP (packages Mason)
        "lua-language-server",
        "python-lsp-server",
        "ruff-lsp",
        "json-lsp",
        "sqlls",
        "terraform-ls",
        "yaml-language-server",
        "bash-language-server",
        "dockerfile-language-server",
        "docker-compose-language-service",
        "html-lsp",
        "clangd",
        -- Tools
        "tree-sitter-cli",
        "stylua",
      },
      run_on_start = true,
      start_delay = 300,
      -- integrations = { ["mason-lspconfig"] = true }, -- par défaut
    },
  },

  ---------------------------------------------------------------------------
  -- lspconfig + ta config (mappings, autocommands, servers, capabilities)
  ---------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      {
        "j-hui/fidget.nvim",
        opts = {
          notification = { window = { winblend = 0 } },
        },
      },
    },
    config = function()
      -- Autocmd de mappings (inchangé)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
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
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local hl = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
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
            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
              callback = function(ev)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = ev.buf })
              end,
            })
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map("<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, "[T]oggle Inlay [H]ints")
          end
        end,
      })

      -- Capabilities (inchangé)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

      -- Tes serveurs (inchangé, avec petits fix mineurs)
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = "Replace" },
              runtime = { version = "LuaJIT" },
              workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
              },
              diagnostics = { globals = { "vim" }, disable = { "missing-fields" } },
              format = { enable = false },
            },
          },
        },
        pylsp = {
          settings = {
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
          },
        },
        ruff = {},
        jsonls = {},
        sqlls = {},
        terraformls = {},
        yamlls = {},
        bashls = {},
        dockerls = {},
        docker_compose_language_service = {},
        html = { filetypes = { "html", "twig", "hbs" } },
      }

      for server, cfg in pairs(servers) do
        cfg.capabilities = vim.tbl_deep_extend("force", {}, capabilities, cfg.capabilities or {})
        vim.lsp.config(server, cfg)
        vim.lsp.enable(server)
      end
    end,
  },
}
