-- lua/core/dotnet/init.lua
local project = require("core.dotnet.project")
local environment = require("core.dotnet.environment")
local launch = require("core.dotnet.launch")

local M = {}

local term_win, term_buf

local function pick_code_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    if
      ft ~= "neo-tree"
      and ft ~= "aerial"
      and ft ~= "terminal"
      and ft ~= "TelescopePrompt"
      and ft ~= "qf"
    then
      return win
    end
  end
  return vim.api.nvim_get_current_win()
end

local function open_or_reuse_term()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    local new_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(term_win, new_buf)
    term_buf = new_buf
    return
  end
  vim.cmd("botright split | resize 12")
  term_win = vim.api.nvim_get_current_win()
  term_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(term_win, term_buf)
end

local function term_run(argv, cwd, env)
  local return_win = pick_code_win()
  local opts = {}

  if type(cwd) == "string" and cwd ~= "" then
    local st = vim.loop.fs_stat(cwd)
    if st and st.type == "directory" then
      opts.cwd = cwd
    end
  end

  if type(env) == "table" then
    opts.env = env
  end

  open_or_reuse_term()
  vim.fn.termopen(argv, opts)
  vim.bo[term_buf].modifiable = false
  vim.cmd("startinsert")

  local grp = vim.api.nvim_create_augroup("DotnetTermFocus", { clear = true })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = grp,
    pattern = tostring(term_win),
    once = true,
    callback = function()
      vim.schedule(function()
        if return_win and vim.api.nvim_win_is_valid(return_win) then
          pcall(vim.api.nvim_set_current_win, return_win)
        else
          pcall(vim.api.nvim_set_current_win, pick_code_win())
        end
      end)
    end,
  })
end

local function run_with_config(config)
  local csproj = project.find_csproj()
  if not csproj then
    vim.notify("Aucun .csproj trouvé.", vim.log.levels.ERROR)
    return
  end

  local dll = project.guess_dll(csproj, config)
  if not dll or dll == "" then
    vim.notify("Impossible de déterminer le DLL (" .. config .. ").", vim.log.levels.ERROR)
    return
  end

  if not vim.loop.fs_stat(dll) then
    vim.notify("Build initial (" .. config .. ")…", vim.log.levels.WARN)
    vim.fn.system({ "dotnet", "build", "-c", config, csproj })
  end

  local proj_dir = vim.fn.fnamemodify(csproj, ":h")
  local profiles = launch.parse_launch_settings(proj_dir)

  launch.choose_profile_or_none(profiles, function(profile)
    local env_dict = environment.build_env_dict(profile, proj_dir, config)

    local run_cwd = proj_dir
    if profile and type(profile.workingDirectory) == "string" and profile.workingDirectory ~= "" then
      local wd = profile.workingDirectory
      if not wd:match("^/") and not wd:match("^%a:[/\\]") then
        wd = proj_dir .. "/" .. wd
      end
      if vim.loop.fs_stat(wd) then
        run_cwd = wd
      end
    end

    local extra = {}
    if profile and type(profile.commandLineArgs) == "string" and profile.commandLineArgs ~= "" then
      extra = launch.shell_split_args(profile.commandLineArgs)
    end

    local argv = { "dotnet", dll }
    for _, a in ipairs(extra) do
      table.insert(argv, a)
    end
    term_run(argv, run_cwd, env_dict)
  end)
end

function M.build_release()
  local proj = project.find_csproj()
  if not proj then
    vim.notify("Aucun .csproj trouvé.", vim.log.levels.ERROR)
    return
  end
  term_run({ "dotnet", "build", "-c", "Release", proj }, vim.fn.fnamemodify(proj, ":h"))
end

function M.build_debug()
  local proj = project.find_csproj()
  if not proj then
    vim.notify("Aucun .csproj trouvé.", vim.log.levels.ERROR)
    return
  end
  term_run({ "dotnet", "build", "-c", "Debug", proj }, vim.fn.fnamemodify(proj, ":h"))
end

function M.run_release()
  run_with_config("Release")
end

function M.run()
  run_with_config("Debug")
end

function M.test()
  term_run({ "dotnet", "test" }, vim.fn.getcwd())
end

function M.publish()
  local proj = project.find_csproj()
  if not proj then
    vim.notify("Aucun .csproj trouvé.", vim.log.levels.ERROR)
    return
  end
  term_run({
    "dotnet",
    "publish",
    "-c",
    "Release",
    "-o",
    "out",
    "--nologo",
    "--verbosity",
    "minimal",
    "--project",
    proj,
  }, vim.fn.fnamemodify(proj, ":h"))
end

function M.new_console()
  local name = vim.fn.input("Nom du projet : ")
  if name == "" then
    return
  end
  term_run({ "dotnet", "new", "console", "-n", name }, vim.fn.getcwd())
  local sln = vim.fn.glob("*.sln")
  if sln ~= "" then
    vim.fn.system({ "dotnet", "sln", sln, "add", name .. "/" .. name .. ".csproj" })
    vim.notify("Projet '" .. name .. "' ajouté à la solution " .. sln, vim.log.levels.INFO)
  else
    vim.notify("Projet '" .. name .. "' créé (pas de solution trouvée).", vim.log.levels.WARN)
  end
  local prog = name .. "/Program.cs"
  if vim.loop.fs_stat(prog) then
    vim.cmd("vsplit " .. prog)
  end
end

-- Export submodules
M.project = project
M.environment = environment
M.launch = launch

return M
