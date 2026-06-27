# =====================================
# Paths
# =====================================

$paths = @(
  "/usr/local/sbin",
  "/usr/local/bin",
  "/usr/sbin",
  "/usr/bin",
  "/sbin",
  "/bin",
  "/home/summer/.local/bin",
  "/home/summer/.opencode/bin/"
)

$paths += ($env:PATH -split ":")
$paths = $paths | Select-Object -Unique
$env:PATH = $paths -join ":"

# =====================================
# PSReadLine
# =====================================

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle List
Set-PSReadLineOption -EditMode Vi

# =====================================
# Aliases
# =====================================

# Set by default on Windows, but not Linux
Set-Alias cat Get-Content
Set-Alias cp Copy-Item
Set-Alias ls Get-ChildItem
Set-Alias mv Move-Item
Set-Alias rm Remove-Item
Set-Alias sort Sort-Item

Set-Alias python python3

# =====================================
# Oh My Posh
# =====================================

# https://ohmyposh.dev/
oh-my-posh init pwsh --config "/home/summer/ProgrammingProjects/AgentConfig/dotfiles/pwsh/oh-my-posh-config.omp.json" | Invoke-Expression
