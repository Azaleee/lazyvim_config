-- lua/core/dotnet/project.lua
local M = {}

function M.find_csproj()
  local buf_dir = vim.fn.expand("%:p:h")
  local local_match = vim.fn.globpath(buf_dir, "*.csproj", false, true)
  if #local_match > 0 then
    return local_match[1]
  end

  local cwd_match = vim.fn.glob("*.csproj", false, true)
  if #cwd_match > 0 then
    return cwd_match[1]
  end

  local matches = vim.fn.glob("**/*.csproj", false, true)
  if #matches > 0 then
    return matches[1]
  end

  return nil
end

function M.git_root(start_dir)
  local out = vim.fn.systemlist({ "git", "-C", start_dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out and out[1] and out[1] ~= "" then
    return out[1]
  end
  return nil
end

function M.sln_root(start_dir)
  local dir = vim.fn.fnamemodify(start_dir, ":p")
  while dir and dir ~= "" do
    local matches = vim.fn.globpath(dir, "*.sln", false, true)
    if matches and #matches > 0 then
      return (dir:gsub("[/\\]+$", ""))
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

function M.ancestors(start_dir)
  local dir = vim.fn.fnamemodify(start_dir, ":p")
  local res = {}
  while dir and dir ~= "" do
    res[#res + 1] = (dir:gsub("[/\\]+$", ""))
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return res
end

function M.read_tfm(csproj)
  local ok, lines = pcall(vim.fn.readfile, csproj)
  if not ok or not lines then
    return nil
  end
  local txt = table.concat(lines, "\n")

  local tfm = txt:match("<TargetFramework>%s*(.-)%s*</TargetFramework>")
  if tfm and #tfm > 0 then
    return tfm
  end

  local tfms = txt:match("<TargetFrameworks>%s*(.-)%s*</TargetFrameworks>")
  if tfms and #tfms > 0 then
    local first = tfms:match("([^;%s]+)")
    if first then
      return first
    end
  end

  return nil
end

function M.guess_dll(csproj, config)
  local proj_dir = vim.fn.fnamemodify(csproj, ":h")
  local proj_name = vim.fn.fnamemodify(csproj, ":t:r")
  local tfm = M.read_tfm(csproj)

  local candidates = {}

  if tfm then
    table.insert(candidates, string.format("%s/bin/%s/%s/%s.dll", proj_dir, config, tfm, proj_name))
  end

  vim.list_extend(candidates, {
    string.format("%s/bin/%s/net9.0/%s.dll", proj_dir, config, proj_name),
    string.format("%s/bin/%s/net8.0/%s.dll", proj_dir, config, proj_name),
    string.format("%s/bin/%s/net7.0/%s.dll", proj_dir, config, proj_name),
  })

  for _, dll in ipairs(candidates) do
    if vim.loop.fs_stat(dll) then
      return dll
    end
  end

  return candidates[1]
end

function M.read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*all")
  f:close()
  return content
end

function M.ensure_cwd(cwd)
  if type(cwd) ~= "string" or cwd == "" then
    return nil
  end
  if vim.loop.fs_stat(cwd) and vim.loop.fs_stat(cwd).type == "directory" then
    return cwd
  end
  return nil
end

return M
