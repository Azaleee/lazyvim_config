-- lua/plugins/dap.lua
return {
  -- Mason DAP bridge (installe auto les adaptateurs)
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    opts = {
      ensure_installed = { "coreclr" },   -- => installe netcoredbg
      automatic_installation = true,
      handlers = {},                      -- on configure manuellement plus bas
    },
  },

  -- nvim-dap + UI + virtual text
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "jay-babu/mason-nvim-dap.nvim",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      ------------------------------------------------------------------------
      -- 1) Adapter .NET (coreclr) : priorité au binaire Mason (auto-installé)
      ------------------------------------------------------------------------
      local function mason_path(...)
        return table.concat({ vim.fn.stdpath("data"), "mason", ... }, "/")
      end

      local netcoredbg = mason_path("packages", "netcoredbg", "netcoredbg")
      if vim.fn.executable(netcoredbg) ~= 1 then
        -- fallback : binaire utilisateur (~/.local/bin/netcoredbg)
        local manual = vim.fn.expand("~/.local/bin/netcoredbg")
        if vim.fn.executable(manual) == 1 then
          netcoredbg = manual
        end
      end

      if vim.fn.executable(netcoredbg) == 1 then
        dap.adapters.coreclr = {
          type = "executable",
          command = netcoredbg,
          args = { "--interpreter=vscode" },
        }
      else
        vim.notify(
          "netcoredbg introuvable. Ouvre :Mason puis installe 'coreclr' (ou relance pour auto-install).",
          vim.log.levels.ERROR
        )
      end

      ------------------------------------------------------------------------
      -- 2) Outils projet .NET (détection .csproj / dll / launchSettings.json)
      ------------------------------------------------------------------------
      local last_csproj

      local function nearest_csproj_from_buffer()
        local bufpath = vim.api.nvim_buf_get_name(0)
        local start_dir = (bufpath ~= "" and vim.fn.fnamemodify(bufpath, ":p:h")) or vim.fn.getcwd()
        local found = vim.fs.find(function(name) return name:match("%.csproj$") end,
          { path = start_dir, upward = true, stop = vim.loop.os_homedir(), limit = 1 })
        return found[1]
      end

      local function read_file(path)
        local ok, data = pcall(vim.fn.readfile, path)
        if not ok or not data or #data == 0 then return nil end
        return table.concat(data, "\n")
      end

      local function read_tfm(csproj)
        local txt = read_file(csproj); if not txt then return nil end
        local tfm = txt:match("<TargetFramework>%s*(.-)%s*</TargetFramework>")
        if tfm and #tfm > 0 then return tfm end
        local tfms = txt:match("<TargetFrameworks>%s*(.-)%s*</TargetFrameworks>")
        if tfms and #tfms > 0 then
          local first = tfms:match("([^;%s]+)")
          if first then return first end
        end
        return nil
      end

      local function dll_for_csproj(csproj)
        local dir  = vim.fn.fnamemodify(csproj, ":h")
        local name = vim.fn.fnamemodify(csproj, ":t:r")
        local tfm  = read_tfm(csproj)
        local candidates = {}
        if tfm then table.insert(candidates, string.format("%s/bin/Debug/%s/%s.dll", dir, tfm, name)) end
        vim.list_extend(candidates, {
          string.format("%s/bin/Debug/net9.0/%s.dll", dir, name),
          string.format("%s/bin/Debug/net8.0/%s.dll", dir, name),
          string.format("%s/bin/Debug/net7.0/%s.dll", dir, name),
        })
        for _, p in ipairs(candidates) do
          if vim.loop.fs_stat(p) then return p end
        end
        return candidates[1]
      end

      local function find_csproj()
        if last_csproj and vim.loop.fs_stat(last_csproj) then return last_csproj end
        local near = nearest_csproj_from_buffer()
        if near then return near end
        local any = vim.fs.find(function(n) return n:match("%.csproj$") end,
          { path = vim.fn.getcwd(), type = "file", limit = 1 })
        return any[1]
      end

      local function select_project_interactive(cb)
        local all = vim.fs.find(function(n) return n:match("%.csproj$") end,
          { path = vim.fn.getcwd(), type = "file", limit = math.huge })
        if #all == 0 then
          vim.notify("Aucun .csproj trouvé.", vim.log.levels.ERROR); return
        elseif #all == 1 then
          last_csproj = all[1]; if cb then cb(all[1]) end; return
        end
        vim.ui.select(all, { prompt = "Sélectionne le projet (.csproj)" }, function(choice)
          if choice then last_csproj = choice; if cb then cb(choice) end end
        end)
      end

      local function parse_launch_settings(csproj_dir)
        local path = csproj_dir .. "/Properties/launchSettings.json"
        local txt = read_file(path)
        if not txt then return nil end
        local ok, obj = pcall(vim.json.decode, txt)
        if not ok or type(obj) ~= "table" then return nil end
        local profiles = obj.profiles or {}
        local names = {}
        for name, _ in pairs(profiles) do table.insert(names, name) end
        table.sort(names)
        return { map = profiles, list = names, path = path }
      end

      local function choose_cwd(default_dir, cb)
        vim.ui.input({ prompt = "Working directory (cwd): ", default = default_dir }, function(input)
          cb((input and input ~= "") and input or default_dir)
        end)
      end

      local function choose_profile_or_none(profiles, cb)
        if not profiles then cb(nil); return end
        local names = profiles.list
        if #names == 0 then cb(nil); return end
        local items = vim.deepcopy(names)
        table.insert(items, 1, "[Aucun profil]")
        vim.ui.select(items, { prompt = "Launch profile" }, function(choice)
          if not choice or choice == "[Aucun profil]" then cb(nil) else cb(profiles.map[choice]) end
        end)
      end

      ------------------------------------------------------------------------
      -- 3) Config DAP pour C#
      ------------------------------------------------------------------------
      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Launch (.NET) — choose cwd & profile",
          request = "launch",
          program = function()
            local csproj = find_csproj()
            if not csproj then
              select_project_interactive()
              error("Aucun projet sélectionné. Relance F5 après sélection.")
            end
            local dll = dll_for_csproj(csproj)
            if not vim.loop.fs_stat(dll) then
              vim.notify("Build initial du projet: " .. csproj, vim.log.levels.WARN)
              vim.fn.system({ "dotnet", "build", csproj })
            end
            return dll
          end,
          cwd = function()
            local csproj = find_csproj()
            local default_dir = vim.fn.fnamemodify(csproj, ":h")
            local co = coroutine.running()
            return coroutine.create(function()
              choose_cwd(default_dir, function(dir) coroutine.resume(co, dir) end)
            end)
          end,
          env = function()
            local csproj = find_csproj()
            local dir = vim.fn.fnamemodify(csproj, ":h")
            local profiles = parse_launch_settings(dir)
            local co = coroutine.running()
            return coroutine.create(function()
              choose_profile_or_none(profiles, function(profile)
                local e = {}
                if profile and type(profile.environmentVariables) == "table" then
                  for k, v in pairs(profile.environmentVariables) do e[k] = tostring(v) end
                end
                if profile and type(profile.applicationUrl) == "string" and profile.applicationUrl ~= "" then
                  e.ASPNETCORE_URLS = profile.applicationUrl
                end
                coroutine.resume(co, e)
              end)
            end)
          end,
          justMyCode = true,
          stopAtEntry = false,
        },
      }

      ------------------------------------------------------------------------
      -- 4) UI auto & keymaps
      ------------------------------------------------------------------------
      dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui"]      = function() dapui.close() end

      vim.keymap.set("n", "<F5>",  dap.continue,          { desc = "DAP Continue" })
      vim.keymap.set("n", "<F10>", dap.step_over,         { desc = "DAP Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into,         { desc = "DAP Step Into" })
      vim.keymap.set("n", "<S-F11>", dap.step_out,        { desc = "DAP Step Out" })
      vim.keymap.set("n", "<F9>",  dap.toggle_breakpoint, { desc = "DAP Toggle Breakpoint" })
    end,
  },

  -- UI
  { "rcarriga/nvim-dap-ui" },
  { "theHamsta/nvim-dap-virtual-text" },
}
