# Neovim Configuration

> A modern, feature-rich Neovim configuration optimized for C# / .NET development with Visual Studio-inspired workflows.

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)

## 🚀 Features

- **Modern C# Development** with Roslyn LSP (Microsoft's official Language Server)
- **Visual Studio-like Experience** via Lspsaga (peek definitions, hover, finder)
- **Full Debugging Support** with DAP for .NET applications
- **AI-Powered Completion** using GitHub Copilot
- **Advanced Git Integration** with Diffview, Gitsigns, and Telescope
- **LazyVim-based** for optimal performance and lazy-loading
- **Custom .NET Utilities** for building, running, and testing projects

## 📋 Requirements

- **Neovim** >= 0.9.0
- **Node.js** (for Copilot)
- **.NET SDK** 6.0+ (for C# development)
- **Git**
- A [Nerd Font](https://www.nerdfonts.com/) (for icons)

## 🔧 Key Technologies

### LSP Configuration

#### C# / .NET
- **Roslyn LSP** - Microsoft's official language server with full CodeLens support
  - Configured via custom Mason registry (`Crashdummyy/mason-registry`)
  - Auto-installs and configures on first `.cs` file open
  - Features: IntelliSense, CodeLens, refactoring, analyzers

#### Other Languages
- **Lua** - `lua_ls` with Neovim API support
- **Python** - `pylsp` + `ruff` for linting
- **SQL** - `sqlls`
- **YAML/JSON** - `yamlls`, `jsonls`
- **Docker** - `dockerls`, `docker_compose_language_service`
- **Bash** - `bashls`
- **C/C++** - `clangd`
- **Terraform** - `terraformls`

### IDE Features

#### Visual Studio-Style Workflow
*Source: [lua/plugins/vsstyle.lua](lua/plugins/vsstyle.lua)*

- **lsp-lens.nvim** - Shows reference counts above functions
- **Lspsaga** - Peek definitions, fancy hover, rename
- **Telescope** - Dropdown-style pickers for references/definitions
- **Trouble.nvim** - Panel view for references and diagnostics
- **actions-preview.nvim** - `Alt+Enter` code actions like Visual Studio
- **barbecue.nvim** - Breadcrumbs navigation bar

#### Debugging (DAP)
*Source: [lua/plugins/dap.lua](lua/plugins/dap.lua)*

- **netcoredbg** debugger for .NET
- Auto-detects `.csproj` files and builds debug configurations
- Reads `launchSettings.json` for launch profiles
- Parses `.env` files for environment variables
- **F5** to start debugging, **F9** for breakpoints, **F10/F11** for stepping

#### .NET Development Tools
*Source: [lua/core/dotnet.lua](lua/core/dotnet.lua)*

Custom commands for .NET workflows:
- `<leader>mb` - Build (Debug)
- `<leader>mB` - Build (Release)
- `<leader>mr` - Run (Debug)
- `<leader>mR` - Run (Release)
- `<leader>mt` - Test
- `<leader>mp` - Publish
- `<leader>mc` - New Console Project

Features:
- Auto-detects solution files (`.sln`)
- Parses launch profiles from `launchSettings.json`
- Environment variable support via `.env` files
- Terminal integration with ToggleTerm

### AI & Completion

#### GitHub Copilot
*Source: [lua/plugins/copilot.lua](lua/plugins/copilot.lua)*

- **Copilot** - AI code suggestions (`Ctrl+;` to accept)
- **CopilotChat** - Interactive AI chat for code explanations
  - `<leader>cc` - Open chat
  - `<leader>ce` - Explain code
  - `<leader>cf` - Fix code issues

#### Completion Engine
*Source: [lua/plugins/nvim-cmp.lua](lua/plugins/nvim-cmp.lua)*

- **nvim-cmp** with multiple sources:
  - LSP completion
  - Buffer words
  - File paths
  - Luasnip snippets
  - Copilot suggestions

### File Navigation

- **nvim-tree.nvim** - File explorer (`<leader>e`)
- **Telescope** - Fuzzy finder for files, buffers, grep
- **Harpoon** - Quick file bookmarks (`<leader>ha/hh/h1-4`)
- **Aerial** - Code outline (`<leader>a`)

### Git Integration

- **Diffview** - Rich diff viewer (`<leader>gd`)
- **Gitsigns** - Git decorations in sign column
- **Telescope** - Git file/commit/branch search
- **Fugitive** - Git commands

### Terminal

- **ToggleTerm** - Floating terminal (`Ctrl+/`)
- Custom .NET terminal commands with output capture

## 📁 Configuration Structure

```
~/.config/nvim/
├── init.lua                    # Entry point
├── lua/
│   ├── config/
│   │   ├── keymaps.lua        # Global keymaps
│   │   ├── lazy.lua           # Lazy.nvim bootstrap
│   │   ├── options.lua        # Neovim options
│   │   ├── roslyn-config.lua  # Roslyn LSP config
│   │   └── utils.lua          # Utility functions
│   ├── core/
│   │   └── dotnet.lua         # .NET development utilities
│   └── plugins/
│       ├── lsp.lua            # LSP configuration
│       ├── roslyn.lua         # Roslyn LSP plugin
│       ├── dap.lua            # Debugging config
│       ├── vsstyle.lua        # VS-style IDE features
│       ├── telescope.lua      # Fuzzy finder
│       ├── copilot.lua        # AI completion
│       ├── nvim-tree.lua      # File explorer
│       ├── colorscheme.lua    # Theme configuration
│       └── ...                # Other plugins
├── KEYMAPS.md                 # Complete keymap reference
└── README.md                  # This file
```

## ⌨️ Key Bindings

**Leader Key**: `<Space>`

For a complete list of all keymaps, see [KEYMAPS.md](KEYMAPS.md).

### Essential Shortcuts

| Keymap | Description |
|--------|-------------|
| `<leader>sf` | Search files (Telescope) |
| `<leader>sg` | Live grep (search text) |
| `<leader>e` | Toggle file explorer |
| `gd` | Peek definition (Lspsaga) |
| `gr` | Find references (Telescope) |
| `<leader>ca` | Code actions |
| `<leader>rn` | Rename symbol |
| `<F5>` | Start debugging |
| `<F9>` | Toggle breakpoint |
| `<Ctrl-/>` | Toggle terminal |
| `<leader>cc` | Open Copilot Chat |

## 🎨 Customization

### C# LSP Configuration

The Roslyn LSP is configured in [lua/plugins/roslyn.lua](lua/plugins/roslyn.lua). To install:

```vim
:RoslynInstall
```

This will download and configure Microsoft's Roslyn language server.

### Mason Registry

Uses a custom Mason registry for Roslyn support:
```lua
opts = {
  registries = {
    "github:mason-org/mason-registry",
    "github:Crashdummyy/mason-registry",  -- For Roslyn
  },
}
```

### Adding Language Servers

Edit [lua/plugins/lsp.lua](lua/plugins/lsp.lua):

```lua
ensure_installed = {
  "lua_ls",
  "pylsp",
  -- Add your LSP here
},
```

## 🐛 Debugging

### .NET Debugging Setup

1. Ensure `netcoredbg` is installed via Mason:
   ```vim
   :Mason
   ```

2. Open a C# project with a `.csproj` file

3. Press `F5` to start debugging

4. DAP will:
   - Auto-detect your project
   - Build in Debug mode
   - Parse `launchSettings.json` if present
   - Load environment variables from `.env`
   - Launch the debugger

### Launch Profiles

If your project has `Properties/launchSettings.json`, DAP will:
- Detect available launch profiles
- Prompt you to select one
- Apply environment variables and arguments

## 📝 Notes

### Known Issues

1. **Keymap Conflicts**: Some keymaps are defined in multiple places (LSP vs Lspsaga). Lspsaga bindings take precedence. See [KEYMAPS.md](KEYMAPS.md#keymap-conflicts) for details.

2. **Roslyn Startup**: First-time Roslyn setup may take 1-2 minutes to download the language server.

3. **CodeLens**: CodeLens (reference counts above methods) require Roslyn LSP. `csharp_ls` is blocked in favor of Roslyn.

### Performance Tips

- Plugins are lazy-loaded where possible
- LSP servers start only when needed (on filetype)
- Mason auto-installs missing tools

## 🤝 Contributing

This is a personal configuration, but feel free to:
- Report issues
- Suggest improvements
- Fork and customize for your needs

## 📜 License

This configuration is free to use and modify.

## 🙏 Credits

Built with:
- [LazyVim](https://github.com/LazyVim/LazyVim)
- [Roslyn](https://github.com/seblj/roslyn.nvim)
- [Lspsaga](https://github.com/nvimdev/lspsaga.nvim)
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- [Telescope](https://github.com/nvim-telescope/telescope.nvim)
- And many other amazing plugins!

---

**Last Updated**: November 2025
