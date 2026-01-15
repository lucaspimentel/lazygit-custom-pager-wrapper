#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Builds and installs lazygit-custom-pager-wrapper from source.

.DESCRIPTION
    This script builds the lazygit-custom-pager-wrapper CLI tool from source and installs it
    to ~/.local/bin/lazygit-custom-pager-wrapper (or ~/.local/bin/lazygit-custom-pager-wrapper.exe on Windows).

    Requirements:
    - PowerShell 7.0+
    - .NET SDK

.EXAMPLE
    ./install-local.ps1

    Builds and installs lazygit-custom-pager-wrapper to ~/.local/bin
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Determine runtime identifier based on platform
$rid = if ($IsWindows) {
    'win-x64'
} elseif ($IsMacOS) {
    if ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -eq 'Arm64') {
        'osx-arm64'
    } else {
        'osx-x64'
    }
} elseif ($IsLinux) {
    'linux-x64'
} else {
    throw "Unsupported platform"
}

Write-Host "Building lazygit-custom-pager-wrapper for $rid..." -ForegroundColor Cyan

# Build and publish the project
$projectPath = Join-Path $PSScriptRoot 'lazygit-custom-pager-wrapper.csproj'
$publishPath = Join-Path $PSScriptRoot 'artifacts/publish/lazygit-custom-pager-wrapper/release'

try {
    dotnet publish $projectPath `
        -c Release `
        -r $rid `
        --output $publishPath

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "Failed to build project: $_"
    exit 1
}

# Determine executable name
$exeName = if ($IsWindows) { 'lazygit-custom-pager-wrapper.exe' } else { 'lazygit-custom-pager-wrapper' }
$exePath = Join-Path $publishPath $exeName

if (-not (Test-Path $exePath)) {
    Write-Error "Build succeeded but executable not found at: $exePath"
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green

# Install to ~/.local/bin
$installDir = Join-Path $HOME '.local/bin'
$installPath = Join-Path $installDir $exeName

# Create installation directory if it doesn't exist
if (-not (Test-Path $installDir)) {
    Write-Host "Creating installation directory: $installDir" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Remove existing installation if present
if (Test-Path $installPath) {
    Write-Host "Removing existing installation..." -ForegroundColor Yellow
    Remove-Item $installPath -Force
}

# Copy executable to installation directory
Write-Host "Installing to: $installPath" -ForegroundColor Cyan
Copy-Item $exePath $installPath -Force

# Set executable permissions on Unix systems
if (-not $IsWindows) {
    chmod +x $installPath
}

Write-Host "`nInstallation complete!" -ForegroundColor Green
Write-Host "`nTo use lazygit-custom-pager-wrapper, ensure ~/.local/bin is in your PATH:" -ForegroundColor Cyan

if ($IsWindows) {
    Write-Host @"

Add to your PowerShell profile ($PROFILE):
    `$env:PATH = "`$HOME\.local\bin;`$env:PATH"

Then restart your shell or run:
    . `$PROFILE

"@ -ForegroundColor White
} else {
    Write-Host @"

Add to your PowerShell profile ($PROFILE):
    `$env:PATH = "`$HOME/.local/bin:`$env:PATH"

Or add to your shell's rc file (~/.bashrc, ~/.zshrc, etc.):
    export PATH="`$HOME/.local/bin:`$PATH"

Then restart your shell or source the file.

"@ -ForegroundColor White
}

Write-Host "Usage:" -ForegroundColor Cyan
Write-Host '    lazygit-custom-pager-wrapper <mergedPath> <localPath> <unused> <unused> <remotePath>' -ForegroundColor White
