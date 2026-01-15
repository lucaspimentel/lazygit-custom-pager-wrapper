# lazygit-custom-pager-wrapper

A high-performance custom pager wrapper for [lazygit](https://github.com/jesseduffield/lazygit) merge conflict resolution. This tool processes `git diff` output to replace temporary file paths with the actual merged file path, providing cleaner and more intuitive diff displays during merge conflict resolution.

## Features

- **Blazing Fast**: Built with .NET 10 Native AOT compilation for sub-millisecond startup time
- **Tiny Binary**: ~2MB self-contained executable with no runtime dependencies
- **Zero Allocation Hot Path**: Uses stack allocation and spans for optimal performance
- **Cross-Platform**: Supports Windows, macOS (x64/ARM64), and Linux

## Why This Tool?

When resolving merge conflicts in lazygit, the default merge tool pager shows diffs with cryptic temporary file paths. This wrapper intercepts the diff output and replaces those temporary paths with the actual file being merged, making the diff much more readable.

**Before:**
```diff
diff --git a/.git/tmp/mergefile_abc123 b/.git/tmp/mergefile_xyz789
```

**After:**
```diff
diff --git a/src/MyFile.cs b/src/MyFile.cs
```

## Installation

### Quick Install (Recommended)

Clone the repository and run the install script:

```powershell
git clone https://github.com/lucaspimentel/lazygit-custom-pager-wrapper.git
cd lazygit-custom-pager-wrapper
./install-local.ps1
```

This will build and install the binary to `~/.local/bin/lazygit-custom-pager-wrapper` (or `.exe` on Windows).

### Manual Installation

1. **Build the project:**
   ```bash
   dotnet publish -c Release -r <RID>
   ```
   Replace `<RID>` with your runtime identifier:
   - Windows: `win-x64`
   - macOS Intel: `osx-x64`
   - macOS Apple Silicon: `osx-arm64`
   - Linux: `linux-x64`

2. **Copy the executable to your PATH:**
   ```bash
   cp artifacts/publish/lazygit-custom-pager-wrapper/release/lazygit-custom-pager-wrapper ~/.local/bin/
   chmod +x ~/.local/bin/lazygit-custom-pager-wrapper  # Unix only
   ```

3. **Ensure `~/.local/bin` is in your PATH:**
   ```bash
   # Add to ~/.bashrc, ~/.zshrc, or PowerShell profile
   export PATH="$HOME/.local/bin:$PATH"
   ```

## Configuration

### Lazygit Setup

Add the following to your lazygit configuration file:

**Location:**
- Linux/macOS: `~/.config/lazygit/config.yml`
- Windows: `C:\Users\<username>\.config\lazygit\config.yml`

**Basic Configuration:**
```yaml
git:
  pagers:
    - externalDiffCommand: lazygit-custom-pager-wrapper
```

**Advanced: Pipe Through Delta (Recommended)**

For syntax highlighting and better diff visualization:

```yaml
git:
  pagers:
    - externalDiffCommand: "lazygit-custom-pager-wrapper | delta --features=\"lazygit\" --width=%LAZYGIT_COLUMNS%"
```

Or create a wrapper script (e.g., `~/.local/bin/lazygit-pager.bat` on Windows):
```batch
@echo off
lazygit-custom-pager-wrapper %* | delta --features="default-feature lazygit" --width=%LAZYGIT_COLUMNS%
```

Then reference it in config:
```yaml
git:
  pagers:
    - externalDiffCommand: "$USERPROFILE/.local/bin/lazygit-pager.bat"
```

### Alternative: Direct Git Configuration

You can also configure this tool directly in your git config if you use it outside of lazygit:

```bash
git config --global mergetool.customdiff.cmd 'lazygit-custom-pager-wrapper "$MERGED" "$LOCAL" "$BASE" "$BASE" "$REMOTE"'
```

## Usage

The tool is designed to be invoked by lazygit automatically. However, you can test it manually:

```bash
lazygit-custom-pager-wrapper <mergedPath> <localPath> <unused> <unused> <remotePath>
```

**Arguments:**
1. `mergedPath` - The actual file path (used in output)
2. `localPath` - Temporary local version path
3. `unused` - Placeholder (required by git merge tool interface)
4. `unused` - Placeholder (required by git merge tool interface)
5. `remotePath` - Temporary remote version path

**Example:**
```bash
lazygit-custom-pager-wrapper src/Program.cs /tmp/local_abc123 x x /tmp/remote_xyz789
```

## Requirements

- **Runtime**: None! This is a self-contained Native AOT binary
- **Build Requirements**: .NET SDK 10.0 or later
- **External Dependencies**: `git` must be available in PATH

## How It Works

1. Receives file paths from lazygit (merged file path + temporary local/remote paths)
2. Normalizes path separators (backslashes → forward slashes)
3. Spawns `git diff --no-index --no-ext-diff` with the local and remote temporary files
4. Processes each line of diff output:
   - Searches for the local or remote temporary path in each line
   - Replaces it with the actual merged file path
   - Outputs the modified line
5. Returns the exit code from the git diff process

## Performance Details

This tool is optimized for speed and low memory usage:

- **Stack Allocation**: Uses `stackalloc` for 2KB line buffers (no heap allocations)
- **Span-Based Processing**: All string operations use `ReadOnlySpan<char>` and `Span<char>`
- **Single-Pass Algorithm**: Replaces paths in one pass (assumes at most one match per line)
- **Native AOT**: Compiled to native code with aggressive optimizations enabled

Typical overhead: **< 1ms** per invocation

## Development

### Building

```bash
# Debug build
dotnet build

# Release build
dotnet build -c Release

# Publish with Native AOT
dotnet publish -c Release -r win-x64
```

### Project Structure

- `Program.cs` - Single-file application with all logic
- `lazygit-custom-pager-wrapper.csproj` - Project file with Native AOT configuration
- `Directory.Build.props` - Build output directory configuration (artifacts/)
- `install-local.ps1` - Cross-platform installation script

### Native AOT Optimizations

The project uses aggressive size and speed optimizations:

```xml
<OptimizationPreference>Speed</OptimizationPreference>
<InvariantGlobalization>true</InvariantGlobalization>
<DebuggerSupport>false</DebuggerSupport>
<StackTraceSupport>false</StackTraceSupport>
<EventSourceSupport>false</EventSourceSupport>
<MetricsSupport>false</MetricsSupport>
```

These settings disable unused .NET features, resulting in a minimal binary size (~2MB).

## Troubleshooting

### Tool Not Found
Ensure `~/.local/bin` is in your PATH:
```bash
echo $PATH | grep .local/bin  # Unix
$env:PATH -split ';' | Select-String local  # PowerShell
```

### Git Not Found
The tool requires `git` to be available in PATH:
```bash
git --version
```

### Lazygit Not Using Custom Pager
Verify your lazygit config:
```bash
# Linux/macOS
cat ~/.config/lazygit/config.yml | grep pager

# Windows
type %APPDATA%\lazygit\config.yml | findstr pager
```

## License

This project is open source. See repository for license details.

## Contributing

Contributions are welcome! This is a simple tool, but if you have ideas for improvements or find bugs, please open an issue or pull request.

## Related Projects

- [lazygit](https://github.com/jesseduffield/lazygit) - A simple terminal UI for git commands
