
-- lua/core/dotnet.lua
local M = {}

-- ========== Utils ==========
local term_win, term_buf

local function ensure_cwd(cwd)
  if type(cwd) ~= "string" or cwd == "" then return nil end
  if vim.loop.fs_stat(cwd) and vim.loop.fs_stat(cwd).type == "directory" then
    return cwd
  end
  return nil
end

-- --- lire launchSettings.json et lister les profils
local function parse_launch_settings(csproj_dir)
  local path = csproj_dir .. "/Properties/launchSettings.json"
  local ok, data = pcall(vim.fn.readfile, path)
  if not ok or not data or #data == 0 then return nil end
  local txt = table.concat(data, "\n")
  local ok2, obj = pcall(vim.json.decode, txt)
  if not ok2 or type(obj) ~= "table" then return nil end
  local profiles = obj.profiles or {}
  local names = {}
  for name, _ in pairs(profiles) do table.insert(names, name) end
  table.sort(names)
  return { map = profiles, list = names, path = path }
end

local function choose_profile_or_none(profiles, cb)
  if not profiles or #profiles.list == 0 then cb(nil); return end
  local items = vim.deepcopy(profiles.list)
  table.insert(items, 1, "[Aucun profil]")
  vim.ui.select(items, { prompt = "Launch profile" }, function(choice)
    if not choice or choice == "[Aucun profil]" then cb(nil) else cb(profiles.map[choice]) end
  end)
end

-- --- détecter le TargetFramework depuis le .csproj
local function read_tfm(csproj)
  local ok, lines = pcall(vim.fn.readfile, csproj)
  if not ok or not lines then return nil end
  local txt = table.concat(lines, "\n")
  local tfm = txt:match("<TargetFramework>%s*(.-)%s*</TargetFramework>")
  if tfm and #tfm > 0 then return tfm end
  local tfms = txt:match("<TargetFrameworks>%s*(.-)%s*</TargetFrameworks>")
  if tfms and #tfms > 0 then
    local first = tfms:match("([^;%s]+)")
    if first then return first end
  end
  return nil
end

-- --- construit le chemin DLL selon Debug/Release
local function guess_dll(csproj, config) -- config = "Debug" | "Release"
  local proj_dir  = vim.fn.fnamemodify(csproj, ":h")
  local proj_name = vim.fn.fnamemodify(csproj, ":t:r")
  local tfm = read_tfm(csproj)

  local candidates = {}
  if tfm then
    table.insert(candidates, string.format("%s/bin/%s/%s/%s.dll", proj_dir, config, tfm, proj_name))
  end
  -- fallback si pas de TFM lu
  vim.list_extend(candidates, {
    string.format("%s/bin/%s/net9.0/%s.dll", proj_dir, config, proj_name),
    string.format("%s/bin/%s/net8.0/%s.dll", proj_dir, config, proj_name),
    string.format("%s/bin/%s/net7.0/%s.dll", proj_dir, config, proj_name),
  })

  for _, dll in ipairs(candidates) do
    if vim.loop.fs_stat(dll) then return dll end
  end
  return candidates[1] -- premier chemin “attendu”
end

local function pick_code_win()
  -- choisit une fenêtre "code" (ni neo-tree/terminal/aerial/etc.)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft  = vim.bo[buf].filetype
    if ft ~= "neo-tree" and ft ~= "aerial" and ft ~= "terminal"
       and ft ~= "TelescopePrompt" and ft ~= "qf" then
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

-- ===== terminal runner (avec retour focus code) =====
-- ===== terminal runner (focus quand TU fermes la fenêtre) =====
-- AVANT :
-- local function term_run(argv, cwd)
-- APRES :
-- term_run(..., env) garde la même signature
local function term_run(argv, cwd, env)
  local return_win = pick_code_win()
  local opts = {}

  if type(cwd) == "string" and cwd ~= "" then
    local st = vim.loop.fs_stat(cwd)
    if st and st.type == "directory" then opts.cwd = cwd end
  end

  -- Neovim attend un DICT { KEY = "VALUE" }
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

local function find_csproj()
  -- Regarde d'abord dans le dossier du fichier courant
  local buf_dir = vim.fn.expand("%:p:h")
  local local_match = vim.fn.globpath(buf_dir, "*.csproj", false, true)
  if #local_match > 0 then
    return local_match[1]
  end

  -- Sinon cherche dans le dossier courant
  local cwd_match = vim.fn.glob("*.csproj", false, true)
  if #cwd_match > 0 then
    return cwd_match[1]
  end

  -- Sinon cherche récursivement (fallback)
  local matches = vim.fn.glob("**/*.csproj", false, true)
  if #matches > 0 then
    return matches[1]
  end

  return ""
end




local function shell_split_args(s)
  -- split naïf (espaces). Si tu as des guillemets complexes, remplace par un vrai parseur.
  if type(s) ~= "string" or s == "" then return {} end
  return vim.fn.split(s)
end


-- lecture basique de .env (KEY=VALUE), gère commentaires, quotes simples/doubles
local function read_dotenv_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then return nil end
  local env = {}
  for _, raw in ipairs(lines) do
    local line = raw:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" and not line:match("^#") then
      -- support "export KEY=VALUE"
      line = line:gsub("^export%s+", "")
      local k, v = line:match("^([A-Za-z_][A-Za-z0-9_]*)%s*=%s*(.*)$")
      if k then
        -- strip quotes
        v = v:gsub("^['\"](.*)['\"]$", "%1")
        env[k] = v
      end
    end
  end
  return env
end


-- ========== Roots helpers (Git / .sln / parents) ==========

local function git_root(start_dir)
  local out = vim.fn.systemlist({ "git", "-C", start_dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out and out[1] and out[1] ~= "" then
    return out[1]
  end
  return nil
end

local function sln_root(start_dir)
  local dir = vim.fn.fnamemodify(start_dir, ":p")
  while dir and dir ~= "" do
    local matches = vim.fn.globpath(dir, "*.sln", false, true)
    if matches and #matches > 0 then
      return (dir:gsub("[/\\]+$", ""))  -- sans trailing slash
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  return nil
end

-- ⚠️ version “safe” sans table.insert (évite l’erreur)
local function ancestors(start_dir)
  local dir = vim.fn.fnamemodify(start_dir, ":p")
  local res = {}
  while dir and dir ~= "" do
    res[#res + 1] = (dir:gsub("[/\\]+$", ""))  -- append
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  return res
end


local function pick_dotenv_file(proj_dir, config)
  local cfg = (config or ""):lower()
  local function variants(base)
    return {
      string.format("%s/.env.%s",   base, cfg),            -- .env.release / .env.debug
      string.format("%s/.env.%s",   base, (config or "")), -- .env.Release / .env.Debug
      string.format("%s/.env.local", base),
      string.format("%s/.env",       base),
    }
  end

  local roots = {}
  local seen  = {}

  local gr = git_root(proj_dir)
  if gr and not seen[gr] then roots[#roots + 1] = gr; seen[gr] = true end

  local sr = sln_root(proj_dir)
  if sr and not seen[sr] then roots[#roots + 1] = sr; seen[sr] = true end

  if not seen[proj_dir] then roots[#roots + 1] = proj_dir; seen[proj_dir] = true end

  for _, d in ipairs(ancestors(proj_dir)) do
    if not seen[d] then roots[#roots + 1] = d; seen[d] = true end
  end

  for _, base in ipairs(roots) do
    for _, p in ipairs(variants(base)) do
      if p and p ~= "" and vim.loop.fs_stat(p) then
        return p
      end
    end
  end
  return nil
end

-- Merge env courant + env du profil, puis convertir en liste "KEY=VALUE"
-- Merge env courant + env du profil -> DICT { KEY = "VALUE" }
-- helper: fusionne env système + profil -> DICT { KEY = "VALUE" }
-- fusionne env système + launchSettings + .env -> DICT { KEY = "VALUE" }
-- fusionne env système + launchSettings + .env -> DICT { KEY = "VALUE" }
local function build_env_dict(profile, proj_dir, config)
  local base = vim.loop.os_environ()

  if profile and type(profile.environmentVariables) == "table" then
    for k, v in pairs(profile.environmentVariables) do base[tostring(k)] = tostring(v) end
  end
  if profile and type(profile.applicationUrl) == "string" and profile.applicationUrl ~= "" then
    base.ASPNETCORE_URLS = profile.applicationUrl
  end

  local dotenv_path = pick_dotenv_file(proj_dir, config)
  if dotenv_path then
    -- (facultatif) log pour vérifier où il l’a trouvé
    -- vim.notify("dotenv: " .. dotenv_path, vim.log.levels.INFO)
    local env_file = read_dotenv_file(dotenv_path)
    if env_file then
      for k, v in pairs(env_file) do base[k] = tostring(v) end
    end
  end

  for k, v in pairs(base) do base[k] = tostring(v) end
  return base
end



-- === run Debug/Release avec launchSettings (env/cwd/args)
local function run_with_config(config)
  local csproj = find_csproj()
  if csproj == "" then
    vim.notify("Aucun .csproj trouvé.", vim.log.levels.ERROR)
    return
  end

  local dll = guess_dll(csproj, config)
  if not dll or dll == "" then
    vim.notify("Impossible de déterminer le DLL (" .. config .. ").", vim.log.levels.ERROR)
    return
  end

  if not vim.loop.fs_stat(dll) then
    vim.notify("Build initial (" .. config .. ")…", vim.log.levels.WARN)
    vim.fn.system({ "dotnet", "build", "-c", config, csproj })
  end

  local proj_dir = vim.fn.fnamemodify(csproj, ":h")
  local profiles = parse_launch_settings(proj_dir)

  choose_profile_or_none(profiles, function(profile)
  local env_dict = build_env_dict(profile, proj_dir, config)

  local run_cwd = proj_dir
  if profile and type(profile.workingDirectory) == "string" and profile.workingDirectory ~= "" then
    local wd = profile.workingDirectory
    if not wd:match("^/") and not wd:match("^%a:[/\\]") then
      wd = proj_dir .. "/" .. wd
    end
    if vim.loop.fs_stat(wd) then run_cwd = wd end
  end

  local extra = {}
  if profile and type(profile.commandLineArgs) == "string" and profile.commandLineArgs ~= "" then
    extra = shell_split_args(profile.commandLineArgs)
  end

  local argv = { "dotnet", dll }
  for _, a in ipairs(extra) do table.insert(argv, a) end
  term_run(argv, run_cwd, env_dict)
end)end



function M.build_release()
  local proj = find_csproj()
  if proj == "" then
    vim.notify("Aucun .csproj trouvé.", vim.log.levels.ERROR)
    return
  end
  term_run({ "dotnet", "build", "-c", "Release", proj }, vim.fn.fnamemodify(proj, ":h"))
end

function M.build_debug()
  local proj = find_csproj()
  if proj == "" then
    vim.notify("Aucun .csproj trouvé.", vim.log.levels.ERROR)
    return
  end
  term_run({ "dotnet", "build", "-c", "Debug", proj }, vim.fn.fnamemodify(proj, ":h"))
end

function M.run_release()
  run_with_config("Release")
end

function M.test()
  term_run({ "dotnet", "test" }, vim.fn.getcwd())
end

function M.publish()
  local proj = find_csproj()
  if proj == "" then
    vim.notify("Aucun .csproj trouvé.", vim.log.levels.ERROR)
    return
  end
  term_run({
    "dotnet", "publish", "-c", "Release", "-o", "out",
    "--nologo", "--verbosity", "minimal", "--project", proj
  }, vim.fn.fnamemodify(proj, ":h"))
end

function M.new_console()
  local name = vim.fn.input("Nom du projet : ")
  if name == "" then return end
  term_run({ "dotnet", "new", "console", "-n", name }, vim.fn.getcwd())
  local sln = vim.fn.glob("*.sln")
  if sln ~= "" then
    vim.fn.system({ "dotnet", "sln", sln, "add", name .. "/" .. name .. ".csproj" })
    vim.notify("Projet '" .. name .. "' ajouté à la solution " .. sln, vim.log.levels.INFO)
  else
    vim.notify("Projet '" .. name .. "' créé (pas de solution trouvée).", vim.log.levels.WARN)
  end
  local prog = name .. "/Program.cs"
  if vim.loop.fs_stat(prog) then vim.cmd("vsplit " .. prog) end
end

return M
