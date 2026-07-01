$profileRoot = Split-Path $PROFILE -Parent

# =====================================
# Paths
# =====================================

if ($IsLinux)
{
    $paths = @(
      "/usr/local/sbin",
      "/usr/local/bin",
      "/usr/sbin",
      "/usr/bin",
      "/sbin",
      "/bin",
      "$HOME/.local/bin",
      "$HOME/.opencode/bin"
    )

    $paths += ($env:PATH -split ":")
    $paths = $paths | Select-Object -Unique
    $env:PATH = $paths -join ":"
}

# =====================================
# PSReadLine
# =====================================

if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue)
{
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle List
    Set-PSReadLineOption -EditMode Vi
}
else
{
    Write-Host "PSReadLine not installed" -ForegroundColor Yellow
}

# =====================================
# Terminal Icons
# =====================================

if ($IsWindows)
{
    if (Get-Module Terminal-Icons -ListAvailable)
    {
        Import-Module Terminal-Icons
    }
    else
    {
        Write-Host "Terminal-Icons not installed" -ForegroundColor Yellow
    }
}

# =====================================
# Aliases
# =====================================

if ($IsLinux)
{
    # Set by default on Windows, but not Linux
    Set-Alias cat Get-Content
    Set-Alias cp Copy-Item
    Set-Alias ls Get-ChildItem
    Set-Alias mv Move-Item
    Set-Alias rm Remove-Item
    Set-Alias sort Sort-Object
    Set-Alias python python3
}

Set-Alias vim nvim
Set-Alias vi nvim

# =====================================
# PSScriptAnalyzer
# =====================================

$analyzerConfigPath = Join-Path $profileRoot "PSScriptAnalyzerSettings.psd1"
$PSDefaultParameterValues['Invoke-ScriptAnalyzer:Settings'] = $analyzerConfigPath

# =====================================
# Oh My Posh
# =====================================

# https://ohmyposh.dev/
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue)
{
    $configurationPath = Join-Path $profileRoot "oh-my-posh-config.omp.json"
    oh-my-posh init pwsh --config $configurationPath | Invoke-Expression
}
else
{
    Write-Host "Oh-My-Posh not installed" -ForegroundColor Yellow
}
