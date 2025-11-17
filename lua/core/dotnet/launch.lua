-- lua/core/dotnet/launch.lua
local project = require("core.dotnet.project")

local M = {}

function M.parse_launch_settings(csproj_dir)
  local path = csproj_dir .. "/Properties/launchSettings.json"
  local ok, data = pcall(vim.fn.readfile, path)
  if not ok or not data or #data == 0 then
    return nil
  end
  local txt = table.concat(data, "\n")
  local ok2, obj = pcall(vim.json.decode, txt)
  if not ok2 or type(obj) ~= "table" then
    return nil
  end
  local profiles = obj.profiles or {}
  local names = {}
  for name, _ in pairs(profiles) do
    table.insert(names, name)
  end
  table.sort(names)
  return { map = profiles, list = names, path = path }
end

function M.choose_profile_or_none(profiles, cb)
  if not profiles or #profiles.list == 0 then
    cb(nil)
    return
  end
  local items = vim.deepcopy(profiles.list)
  table.insert(items, 1, "[Aucun profil]")
  vim.ui.select(items, { prompt = "Launch profile" }, function(choice)
    if not choice or choice == "[Aucun profil]" then
      cb(nil)
    else
      cb(profiles.map[choice])
    end
  end)
end

function M.shell_split_args(s)
  if type(s) ~= "string" or s == "" then
    return {}
  end
  return vim.fn.split(s)
end

return M
