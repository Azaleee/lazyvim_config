-- lua/plugins/lsp.lua
return {
  -- Mason
  {
    "mason-org/mason.nvim",
    config = true,
  },

  -- mason-lspconfig
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    lazy = false,
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "pylsp",
          "ruff",
          "jsonls",
          "sqlls",
          "terraformls",
          "yamlls",
          "bashls",
          "dockerls",
          "docker_compose_language_service",
          "html",
          "clangd",
          "csharp_ls",
        },
        automatic_installation = true,
      })
    end,
  },

  -- nvim-lspconfig
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
      -- Fix PATH pour dotnet (WSL via neovide --wsl)
      local home = vim.fn.expand("$HOME")
      local dotnet_paths = {
        home .. "/.dotnet",
        home .. "/.dotnet/tools",
        "/usr/share/dotnet",
        "/usr/local/share/dotnet",
      }
      
      for _, path in ipairs(dotnet_paths) do
        if vim.fn.isdirectory(path) == 1 then
          vim.env.PATH = path .. ":" .. vim.env.PATH
        end
      end
      
      if not vim.env.DOTNET_ROOT and vim.fn.isdirectory(home .. "/.dotnet") == 1 then
        vim.env.DOTNET_ROOT = home .. "/.dotnet"
      end

      -- Capabilities
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

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

          -- Document highlight
          local client = vim.lsp.get_client_by_id(event.data.client_id)
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
        end,
      })

      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")
      local mason_lspconfig = require("mason-lspconfig")

      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*.cs",
        callback = function()
          for _, client in pairs(vim.lsp.get_active_clients({ name = "csharp_ls" })) do
            if client.supports_method("workspace/diagnostic/refresh") then
              client.request("workspace/diagnostic/refresh", nil, function() end)
            end
          end
        end,
      }) 
      -- Setup automatique via mason-lspconfig
      mason_lspconfig.setup_handlers({
        -- Handler par défaut
        function(server_name)
          local config = {
            capabilities = capabilities,
          }

          -- Config C# avec fix dotnet
          if server_name == "csharp_ls" then
            local dotnet_root = vim.env.DOTNET_ROOT or home .. "/.dotnet"
            
            config.cmd = { vim.fn.stdpath("data") .. "/mason/bin/csharp-ls" }
            config.cmd_env = {
              DOTNET_ROOT = dotnet_root,
              PATH = dotnet_root .. ":" .. (vim.env.PATH or ""),
            }
            config.root_dir = function(fname)
              return util.root_pattern("*.sln", "*.csproj", "global.json")(fname)
                or util.find_git_ancestor(fname)
                or util.path.dirname(fname)
            end
            config.init_options = { AutomaticWorkspaceInit = true }
            config.filetypes = { "cs" }
            config.single_file_support = true
          end

          -- Config Lua
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

          -- Config Python
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

          -- Config HTML
          if server_name == "html" then
            config.filetypes = { "html", "twig", "hbs" }
          end

          lspconfig[server_name].setup(config)
        end,
      })
    end,
  },
}
