-- lua/plugins/dap.lua
return {
  -- Mason DAP : installe les adapters
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    opts = {
      ensure_installed = { "netcoredbg" },
      automatic_installation = true,
    },
  },

  -- nvim-dap + UI
  {
    "mfussenegger/nvim-dap",
    lazy = false,
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = false,
        all_references = true,
        highlight_changed_variables = true,
        virt_text_pos = "inline",
        display_callback = function(variable, _buf, _stackframe, _node)
          return variable.name .. " = " .. tostring(variable.value)
        end,
      })

      vim.fn.sign_define("DapBreakpoint", {
        text = "●",
        texthl = "DapBreakpoint",
        linehl = "",
        numhl = "",
      })

      vim.fn.sign_define("DapBreakpointCondition", {
        text = "◆",
        texthl = "DapBreakpoint",
        linehl = "",
        numhl = "",
      })

      vim.fn.sign_define("DapBreakpointRejected", {
        text = "○",
        texthl = "DapBreakpoint",
        linehl = "",
        numhl = "",
      })

      vim.fn.sign_define("DapStopped", {
        text = "→",
        texthl = "DapStopped",
        linehl = "DapStoppedLine",
        numhl = "",
      })

      vim.fn.sign_define("DapLogPoint", {
        text = "◎",
        texthl = "DapLogPoint",
        linehl = "",
        numhl = "",
      })

      -- Couleurs
      vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" }) -- Rouge vif
      vim.api.nvim_set_hl(0, "DapStopped", { fg = "#ffcc00" }) -- Jaune/or
      vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2e2e2e" }) -- Ligne en gris foncé
      vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" }) -- Bleu

      ------------------------------------------------------------------
      -- Adapter .NET (netcoredbg via Mason)
      ------------------------------------------------------------------
      local netcoredbg_path = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg"

      if vim.fn.executable(netcoredbg_path) ~= 1 then
        netcoredbg_path = vim.fn.exepath("netcoredbg")
      end

      if netcoredbg_path == "" then
        vim.notify("netcoredbg introuvable. Lance :Mason et installe-le.", vim.log.levels.ERROR)
        return
      end

      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
      }

      ------------------------------------------------------------------
      -- Utilitaires (utilise core.dotnet modules)
      ------------------------------------------------------------------
      local dotnet = require("core.dotnet")

      local last_launch_profile_name = nil

      local function find_dll(csproj)
        local dll = dotnet.project.guess_dll(csproj, "Debug")
        if not dll or not vim.loop.fs_stat(dll) then
          local project_name = vim.fn.fnamemodify(csproj, ":t:r")
          vim.notify("Build du projet: " .. project_name, vim.log.levels.WARN)
          vim.fn.system({ "dotnet", "build", csproj })
          dll = dotnet.project.guess_dll(csproj, "Debug")
        end
        return dll
      end

      local function parse_launch_settings(project_dir)
        local profiles_data = dotnet.launch.parse_launch_settings(project_dir)
        if not profiles_data then
          return nil
        end
        return profiles_data.map
      end

      local function select_launch_profile()
        local csproj = dotnet.project.find_csproj()
        if not csproj then
          vim.notify("Aucun .csproj trouvé pour sélectionner un profil", vim.log.levels.ERROR)
          return nil, nil
        end

        local project_dir = vim.fn.fnamemodify(csproj, ":h")
        local profiles = parse_launch_settings(project_dir)
        if not profiles then
          return nil, nil
        end

        if last_launch_profile_name and profiles[last_launch_profile_name] then
          return profiles[last_launch_profile_name], last_launch_profile_name
        end

        local profile_names = vim.tbl_keys(profiles)
        table.sort(profile_names)

        local menu = table.concat(profile_names, "\n")

        local choice = vim.fn.confirm("Sélectionne un launch profile:", menu, 1)

        if choice == 0 then
          return nil, nil
        end

        local selected_name = profile_names[choice]
        local selected_profile = profiles[selected_name]

        if not selected_profile then
          vim.notify("Profil introuvable après sélection", vim.log.levels.ERROR)
          return nil, nil
        end

        last_launch_profile_name = selected_name
        vim.notify("Profil sélectionné: " .. selected_name, vim.log.levels.INFO)

        return selected_profile, selected_name
      end

      ------------------------------------------------------------------
      -- Config DAP pour C# avec launchSettings.json
      ------------------------------------------------------------------
      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Launch .NET (auto + profile)",
          request = "launch",
          args = function()
            local profile = select_launch_profile()
            if not profile or not profile.commandLineArgs then
              return {}
            end

            return vim.split(profile.commandLineArgs, " ", { trimempty = true })
          end,
          program = function()
            local csproj = dotnet.project.find_csproj()
            if not csproj then
              vim.notify("Aucun .csproj trouvé", vim.log.levels.ERROR)
              return nil
            end

            local dll = find_dll(csproj)
            if not dll then
              vim.notify("Impossible de trouver la DLL", vim.log.levels.ERROR)
              return nil
            end

            vim.notify("DLL trouvée: " .. dll, vim.log.levels.INFO)
            return dll
          end,
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
          stopAtEntry = true,
          env = function()
            local profile = select_launch_profile()
            if not profile then
              return {}
            end

            local env = {}

            -- Variables d'env
            if profile.environmentVariables then
              for k, v in pairs(profile.environmentVariables) do
                env[k] = tostring(v)
              end
            end

            -- URL web (ASP.NET Core)
            if profile.applicationUrl then
              env.ASPNETCORE_URLS = profile.applicationUrl
            end

            return env
          end,
        },
      }

      ------------------------------------------------------------------
      -- Keymaps
      ------------------------------------------------------------------
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP Continue" })
      vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP Toggle Breakpoint" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP Step Into" })
      vim.keymap.set("n", "<S-F11>", dap.step_out, { desc = "DAP Step Out" })

      vim.keymap.set("n", "<Leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
      vim.keymap.set("n", "<Leader>do", dapui.open, { desc = "Open DAP UI" })
      vim.keymap.set("n", "<Leader>dc", dapui.close, { desc = "Close DAP UI" })
      vim.keymap.set("n", "<Leader>dr", dap.repl.toggle, { desc = "Toggle DAP REPL" })
      vim.keymap.set("n", "<Leader>dt", dap.terminate, { desc = "Terminate DAP" })
      vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })

      vim.keymap.set({ "n", "v" }, "<Leader>de", function()
        require("dapui").eval()
      end, { desc = "DAP Eval" })

      vim.keymap.set({ "n", "v" }, "<Leader>dE", function()
        require("dapui").eval(nil, { enter = true })
      end, { desc = "DAP Eval (enter)" })

      vim.keymap.set("n", "<Leader>dP", function()
        last_launch_profile_name = nil
        vim.notify("Profil de debug réinitialisé")
      end, { desc = "Reset launch profile" })
    end,
  },

  { "rcarriga/nvim-dap-ui" },
  { "theHamsta/nvim-dap-virtual-text" },
}
