# CLAUDE.md

## Project Overview

Windows-focused custom pager wrapper for lazygit merge conflict diffs. Replaces temporary file paths with the actual merged file path. C# / .NET 10.0 / Native AOT.

## Build Commands

```powershell
./install-local.ps1                      # build + install to ~/.local/bin (also installs lazygit-pager.bat on Windows)
dotnet build -c Release                  # dev build
dotnet publish -c Release -r win-x64     # AOT publish
```

Build output: `artifacts/` (via `Directory.Build.props`).

## Key Constraints

- Single-file app (`Program.cs`): all logic is top-level, no classes
- Hot path uses `stackalloc` (2KB line buffer) and `Span<char>` — avoid heap allocations
- Single-pass path replacement assumes at most one path match per line
- Lines exceeding the 2KB buffer are written unmodified
- `lazygit-pager.bat` pipes output through delta — installed next to the exe on Windows
