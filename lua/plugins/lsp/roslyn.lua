-- lua/plugins/roslyn.lua
return {
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    opts = {},
  },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "roslyn" then
            if vim.lsp.inlay_hint then
              vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
            end

            if vim.lsp.codelens then
              vim.lsp.codelens.refresh()
            end
          end
        end,
      })

      vim.lsp.config("roslyn", {
        settings = {
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
            dotnet_enable_tests_code_lens = true,
          },
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
          },
        },
      })

      return opts
    end,
  },
}
