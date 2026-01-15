# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A high-performance wrapper for git diff operations designed as a custom merge tool pager for lazygit. The tool processes git diff output and replaces local/remote temporary paths with the actual merged file path for cleaner display.

Written in C# (.NET 10.0) and compiled using Native AOT for minimal startup time and small binary size (~2MB).

## Build & Development Commands

### Build and Install Locally
```powershell
./install-local.ps1
```
Builds with Native AOT, publishes for your platform (win-x64/osx-x64/osx-arm64/linux-x64), and installs to `~/.local/bin`.

### Manual Build
```bash
# Development build
dotnet build -c Release

# Publish with Native AOT
dotnet publish -c Release -r win-x64
```

Build output goes to `artifacts/` directory (configured via `Directory.Build.props`).

## Architecture

### Single-File Application
The entire application is in `Program.cs` - a top-level program that:
1. Validates command-line arguments (expects 5 args: mergedPath, localPath, unused, unused, remotePath)
2. Normalizes path separators (backslashes to forward slashes)
3. Spawns `git diff --no-index --no-ext-diff` with the local and remote paths
4. Processes each line of git diff output, replacing temporary paths with the merged path
5. Outputs the modified diff to stdout

### Performance Optimizations
- Uses `stackalloc` for path buffers and line processing (2KB line buffer)
- Spans and ReadOnlySpans throughout to avoid allocations
- Single-pass string replacement (assumes only one path match per line)
- Lines longer than buffer (>2KB) are written directly without processing

### Native AOT Configuration
The `.csproj` file enables Native AOT with aggressive size/speed optimizations:
- `OptimizationPreference>Speed</OptimizationPreference>` - prioritize speed over size
- Disabled features: debugger support, event sources, HTTP/3, metrics, stack traces, UTF-7, binary formatter serialization
- `InvariantGlobalization>true</InvariantGlobalization>` - no culture-specific operations needed
- `UseNativeHttpHandler>true</UseNativeHttpHandler>` - this tool doesn't use HTTP, but if it did

## Project Configuration

- **Target Framework**: net10.0
- **Build System**: Uses `UseArtifactsOutput>true</UseArtifactsOutput>` in `Directory.Build.props`, which places all build outputs in `artifacts/` directory
- **Publishing**: Native AOT compilation produces self-contained, platform-specific executables

## Usage Context

This tool is designed to be used as a custom merge tool pager in lazygit configuration:
```
lazygit-custom-pager-wrapper <mergedPath> <localPath> <unused> <unused> <remotePath>
```

The tool expects git to be available in PATH as it spawns `git diff` subprocesses.

## Lazygit Configuration

Add to `~/.config/lazygit/config.yml` (or `C:\Users\<username>\.config\lazygit\config.yml` on Windows):
```yaml
git:
  pagers:
    - externalDiffCommand: lazygit-custom-pager-wrapper
```

Can also be piped through additional pagers like delta:
```yaml
git:
  pagers:
    - externalDiffCommand: "lazygit-custom-pager-wrapper | delta --features=\"lazygit\" --width=%LAZYGIT_COLUMNS%"
```
