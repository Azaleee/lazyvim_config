-- lua/plugins/telescope.lua
return {
  "nvim-telescope/telescope.nvim",
  branch = "master",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    "nvim-telescope/telescope-ui-select.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = "Telescope",
  keys = {
    { "<leader>sb", "<cmd>Telescope buffers<cr>", desc = "[S]earch existing [B]uffers" },
    { "<leader><tab>", "<cmd>Telescope buffers<cr>", desc = "[S]earch existing [B]uffers" },
    { "<leader><leader>", "<cmd>Telescope buffers<cr>", desc = "[ ] Find existing buffers" },
    { "<leader>sm", "<cmd>Telescope marks<cr>", desc = "[S]earch [M]arks" },
    { "<leader>gf", "<cmd>Telescope git_files<cr>", desc = "Search [G]it [F]iles" },
    { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Search [G]it [C]ommits" },
    { "<leader>gcf", "<cmd>Telescope git_bcommits<cr>", desc = "Search [G]it [C]ommits for current [F]ile" },
    { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Search [G]it [B]ranches" },
    { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Search [G]it [S]tatus (diff view)" },
    { "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "[S]earch [F]iles" },
    { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "[S]earch [H]elp" },
    { "<leader>sw", "<cmd>Telescope grep_string<cr>", desc = "[S]earch current [W]ord" },
    { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "[S]earch by [G]rep" },
    { "<leader>sd", "<cmd>Telescope diagnostics<cr>", desc = "[S]earch [D]iagnostics" },
    { "<leader>sr", "<cmd>Telescope resume<cr>", desc = "[S]earch [R]resume" },
    { "<leader>so", "<cmd>Telescope oldfiles<cr>", desc = "[S]earch Recent Files" },
    {
      "<leader>sds",
      function()
        require("telescope.builtin").lsp_document_symbols({
          symbols = { "Class", "Function", "Method", "Constructor", "Interface", "Module", "Property" },
        })
      end,
      desc = "[S]each LSP document [S]ymbols",
    },
    {
      "<leader>s/",
      function()
        require("telescope.builtin").live_grep({
          grep_open_files = true,
          prompt_title = "Live Grep in Open Files",
        })
      end,
      desc = "[S]earch [/] in Open Files",
    },
    {
      "<leader>/",
      function()
        require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          previewer = false,
        }))
      end,
      desc = "[/] Fuzzily search in current buffer",
    },
  },
  config = function()
    local actions = require("telescope.actions")

    require("telescope").setup({
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "bottom",
            preview_width = 0.6,
          },
        },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-l>"] = actions.select_default,
          },
          n = {
            ["q"] = actions.close,
          },
        },
      },
      pickers = {
        find_files = {
          file_ignore_patterns = { "node_modules", ".git", ".venv" },
          hidden = true,
        },
        buffers = {
          initial_mode = "normal",
          sort_lastused = true,
          mappings = {
            n = {
              ["d"] = actions.delete_buffer,
              ["l"] = actions.select_default,
            },
          },
        },
        marks = {
          initial_mode = "normal",
        },
        oldfiles = {
          initial_mode = "normal",
        },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
      },
    })

    -- Enable telescope extensions
    pcall(require("telescope").load_extension, "fzf")
    pcall(require("telescope").load_extension, "ui-select")
  end,
}
