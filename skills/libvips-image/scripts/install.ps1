#Requires -Version 5.1
<#
.SYNOPSIS
    libvips-image skill installer for Windows

.DESCRIPTION
    Installs libvips system library and pyvips Python package.
    Prefers uv for Python package management.

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -SkipLibvips
    Only install pyvips, skip libvips download

.NOTES
    Run as Administrator if you want system-wide installation.
#>

param(
    [switch]$SkipLibvips,
    [switch]$SkipPyvips,
    [string]$VipsVersion = "8.16.0"
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err { Write-Host "[ERROR] $args" -ForegroundColor Red; exit 1 }

# Check if command exists
function Test-Command { param($Name) return [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue) }

# Get architecture
function Get-Arch {
    if ([Environment]::Is64BitOperatingSystem) { return "w64" } else { return "w32" }
}

# Install libvips
function Install-Libvips {
    Write-Info "Installing libvips..."

    $arch = Get-Arch
    $vipsDir = "$env:LOCALAPPDATA\vips"
    $vipsBin = "$vipsDir\bin"

    # Check if already installed
    if (Test-Path "$vipsBin\vips.exe") {
        $version = & "$vipsBin\vips.exe" --version 2>$null | Select-Object -First 1
        Write-Success "libvips already installed: $version"

        # Check PATH
        if ($env:PATH -notlike "*$vipsBin*") {
            Write-Warn "libvips bin not in PATH. Adding temporarily..."
            $env:PATH = "$vipsBin;$env:PATH"
        }
        return $vipsBin
    }

    # Try winget first
    if (Test-Command winget) {
        Write-Info "Trying winget..."
        try {
            winget install libvips.libvips --silent 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "libvips installed via winget"
                return $null  # winget handles PATH
            }
        } catch {
            Write-Warn "winget install failed, trying manual download..."
        }
    }

    # Try scoop
    if (Test-Command scoop) {
        Write-Info "Trying scoop..."
        try {
            scoop install libvips 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "libvips installed via scoop"
                return $null
            }
        } catch {
            Write-Warn "scoop install failed, trying manual download..."
        }
    }

    # Manual download
    Write-Info "Downloading libvips manually..."

    $downloadUrl = "https://github.com/libvips/libvips/releases/download/v$VipsVersion/vips-dev-$arch-web-$VipsVersion.zip"
    $zipPath = "$env:TEMP\vips.zip"

    Write-Info "Downloading from: $downloadUrl"

    try {
        # Use TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Download
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $zipPath)

        Write-Info "Extracting to: $vipsDir"

        # Remove old installation
        if (Test-Path $vipsDir) {
            Remove-Item -Recurse -Force $vipsDir
        }

        # Extract
        Expand-Archive -Path $zipPath -DestinationPath $env:LOCALAPPDATA -Force

        # Rename extracted folder
        $extractedDir = Get-ChildItem "$env:LOCALAPPDATA\vips-dev-$VipsVersion" -ErrorAction SilentlyContinue
        if ($extractedDir) {
            Move-Item $extractedDir.FullName $vipsDir -Force
        } else {
            # Try alternative naming
            $extractedDir = Get-ChildItem "$env:LOCALAPPDATA" -Filter "vips*" -Directory |
                Where-Object { $_.Name -ne "vips" } |
                Select-Object -First 1
            if ($extractedDir) {
                Move-Item $extractedDir.FullName $vipsDir -Force
            }
        }

        # Clean up
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        # Add to PATH for current session
        $env:PATH = "$vipsBin;$env:PATH"

        # Add to user PATH permanently
        $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($userPath -notlike "*$vipsBin*") {
            Write-Info "Adding libvips to user PATH..."
            [Environment]::SetEnvironmentVariable("PATH", "$vipsBin;$userPath", "User")
            Write-Warn "PATH updated. Restart your terminal for changes to take effect."
        }

        Write-Success "libvips installed to: $vipsDir"
        return $vipsBin

    } catch {
        Write-Err "Failed to download/install libvips: $_"
    }
}

# Install pyvips
function Install-Pyvips {
    Write-Info "Installing pyvips Python package..."

    # Try uv first (preferred)
    if (Test-Command uv) {
        Write-Info "Using uv (preferred)"
        try {
            & uv pip install pyvips 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "pyvips installed via uv"
                return
            }
        } catch {
            Write-Warn "uv pip install failed"
        }
    }

    # Check common uv locations
    $uvPaths = @(
        "$env:USERPROFILE\.cargo\bin\uv.exe",
        "$env:LOCALAPPDATA\uv\uv.exe",
        "$env:LOCALAPPDATA\Programs\uv\uv.exe"
    )

    foreach ($uvPath in $uvPaths) {
        if (Test-Path $uvPath) {
            Write-Info "Found uv at: $uvPath"
            try {
                & $uvPath pip install pyvips 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "pyvips installed via uv"
                    return
                }
            } catch {
                Write-Warn "uv install failed"
            }
        }
    }

    # Offer to install uv
    Write-Warn "uv not found. uv is recommended for faster, more reliable package management."
    $response = Read-Host "Install uv now? [Y/n]"

    if ($response -notmatch '^[Nn]') {
        Write-Info "Installing uv..."
        try {
            Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression

            # Refresh PATH
            $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                        [Environment]::GetEnvironmentVariable("PATH", "User")

            if (Test-Command uv) {
                & uv pip install pyvips 2>&1 | Out-Null
                Write-Success "pyvips installed via uv"
                return
            }
        } catch {
            Write-Warn "uv installation failed, falling back to pip..."
        }
    }

    # Fallback to pip
    Write-Info "Falling back to pip..."

    $pipCommands = @("pip3", "pip", "python -m pip", "python3 -m pip", "py -m pip")

    foreach ($pipCmd in $pipCommands) {
        try {
            $result = Invoke-Expression "$pipCmd --version" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Info "Using: $pipCmd"
                Invoke-Expression "$pipCmd install pyvips" 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "pyvips installed via pip"
                    return
                }
            }
        } catch {
            continue
        }
    }

    Write-Err "No suitable pip found. Please install Python with pip."
}

# Verify installation
function Test-Installation {
    param($VipsBinPath)

    Write-Info "Verifying installation..."

    # Find Python
    $pythonCommands = @("python", "python3", "py")
    $python = $null

    foreach ($py in $pythonCommands) {
        if (Test-Command $py) {
            $python = $py
            break
        }
    }

    if (-not $python) {
        Write-Err "Python not found"
    }

    Write-Info "Using Python: $python"

    # Set VIPS_PATH if we have it
    if ($VipsBinPath) {
        $env:PATH = "$VipsBinPath;$env:PATH"
    }

    # Test pyvips import
    $testCode = "import pyvips; print(f'pyvips {pyvips.__version__}, libvips {pyvips.version(0)}.{pyvips.version(1)}.{pyvips.version(2)}')"

    try {
        $result = & $python -c $testCode 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Installation verified: $result"
            return $true
        }
    } catch {
        # Ignore
    }

    # Check if libvips DLL can be found
    if ($VipsBinPath -and (Test-Path "$VipsBinPath\libvips-42.dll")) {
        Write-Warn "pyvips installed but cannot find libvips DLL."
        Write-Warn ""
        Write-Warn "Make sure libvips bin is in your PATH:"
        Write-Warn "  `$env:PATH = `"$VipsBinPath;`$env:PATH`""
        Write-Warn ""
        Write-Warn "Or add permanently via System Properties > Environment Variables"
        Write-Warn ""
        Write-Success "Installation complete (PATH configuration may be needed)"
        return $true
    }

    Write-Err "pyvips import failed. Please check libvips installation."
    return $false
}

# Print usage
function Show-Usage {
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "  libvips-image skill installed successfully!" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage examples:"
    Write-Host ""
    Write-Host "  # Using run.bat (recommended):"
    Write-Host "  .\scripts\run.bat vips_tool.py resize input.jpg output.jpg --width 800"
    Write-Host ""
    Write-Host "  # Using Python directly:"
    Write-Host "  python scripts\vips_tool.py resize input.jpg output.jpg --width 800"
    Write-Host ""
    Write-Host "  # Batch processing:"
    Write-Host "  python scripts\vips_batch.py resize .\input .\output --width 800"
    Write-Host ""
    Write-Host "For more commands, run: python scripts\vips_tool.py --help"
    Write-Host ""
}

# Main
function Main {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  libvips-image Skill Installer" -ForegroundColor Cyan
    Write-Host "  Windows Edition" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $vipsBinPath = $null

    if (-not $SkipLibvips) {
        $vipsBinPath = Install-Libvips
    }

    if (-not $SkipPyvips) {
        Install-Pyvips
    }

    Test-Installation -VipsBinPath $vipsBinPath
    Show-Usage
}

Main
