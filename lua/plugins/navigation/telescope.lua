return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
    "nvim-telescope/telescope-ui-select.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>sb", "<cmd>Telescope buffers<cr>", desc = "[S]earch Buffers" },
    { "<leader><tab>", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<leader><leader>", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
    { "<leader>sm", "<cmd>Telescope marks<cr>", desc = "[S]earch Marks" },
    { "<leader>gf", "<cmd>Telescope git_files<cr>", desc = "Git Files" },
    { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },
    { "<leader>gcf", "<cmd>Telescope git_bcommits<cr>", desc = "Git Commits (file)" },
    { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Git Branches" },
    { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git Status" },
    { "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "[S]earch Files" },
    { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "[S]earch Help" },
    { "<leader>sw", "<cmd>Telescope grep_string<cr>", desc = "[S]earch Word" },
    { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "[S]earch by Grep" },
    { "<leader>sd", "<cmd>Telescope diagnostics<cr>", desc = "[S]earch Diagnostics" },
    { "<leader>sr", "<cmd>Telescope resume<cr>", desc = "[S]earch Resume" },
    { "<leader>so", "<cmd>Telescope oldfiles<cr>", desc = "[S]earch Old files" },
    {
      "<leader>sds",
      function()
        require("telescope.builtin").lsp_document_symbols({
          symbols = { "Class", "Function", "Method", "Constructor", "Interface", "Module", "Property" },
        })
      end,
      desc = "[S]earch Document Symbols",
    },
    {
      "<leader>s/",
      function()
        require("telescope.builtin").live_grep({
          grep_open_files = true,
          prompt_title = "Live Grep in Open Files",
        })
      end,
      desc = "[S]earch in Open Files",
    },
    {
      "<leader>/",
      function()
        require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          previewer = false,
        }))
      end,
      desc = "Fuzzy search in buffer",
    },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
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
        marks = { initial_mode = "normal" },
        oldfiles = { initial_mode = "normal" },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
      },
    })

    pcall(telescope.load_extension, "fzf")
    pcall(telescope.load_extension, "ui-select")
  end,
}
