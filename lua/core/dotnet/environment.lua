-- lua/core/dotnet/environment.lua
local project = require("core.dotnet.project")

local M = {}

function M.read_dotenv_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then
    return nil
  end
  local env = {}
  for _, raw in ipairs(lines) do
    local line = raw:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" and not line:match("^#") then
      line = line:gsub("^export%s+", "")
      local k, v = line:match("^([A-Za-z_][A-Za-z0-9_]*)%s*=%s*(.*)$")
      if k then
        v = v:gsub("^['\"](.*)['\"]$", "%1")
        env[k] = v
      end
    end
  end
  return env
end

function M.pick_dotenv_file(proj_dir, config)
  local cfg = (config or ""):lower()
  local function variants(base)
    return {
      string.format("%s/.env.%s", base, cfg),
      string.format("%s/.env.%s", base, (config or "")),
      string.format("%s/.env.local", base),
      string.format("%s/.env", base),
    }
  end

  local roots = {}
  local seen = {}

  local gr = project.git_root(proj_dir)
  if gr and not seen[gr] then
    roots[#roots + 1] = gr
    seen[gr] = true
  end

  local sr = project.sln_root(proj_dir)
  if sr and not seen[sr] then
    roots[#roots + 1] = sr
    seen[sr] = true
  end

  if not seen[proj_dir] then
    roots[#roots + 1] = proj_dir
    seen[proj_dir] = true
  end

  for _, d in ipairs(project.ancestors(proj_dir)) do
    if not seen[d] then
      roots[#roots + 1] = d
      seen[d] = true
    end
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

function M.build_env_dict(profile, proj_dir, config)
  local base = vim.loop.os_environ()

  if profile and type(profile.environmentVariables) == "table" then
    for k, v in pairs(profile.environmentVariables) do
      base[tostring(k)] = tostring(v)
    end
  end
  if profile and type(profile.applicationUrl) == "string" and profile.applicationUrl ~= "" then
    base.ASPNETCORE_URLS = profile.applicationUrl
  end

  local dotenv_path = M.pick_dotenv_file(proj_dir, config)
  if dotenv_path then
    local env_file = M.read_dotenv_file(dotenv_path)
    if env_file then
      for k, v in pairs(env_file) do
        base[k] = tostring(v)
      end
    end
  end

  for k, v in pairs(base) do
    base[k] = tostring(v)
  end
  return base
end

return M
