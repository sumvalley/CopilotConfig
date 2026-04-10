param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "..\permissions.json")
)

$ErrorActionPreference = "Stop"

# Returns the text of every CommandAst node in a compound PowerShell command string.
# Correctly ignores delimiters (|, ;, &&, ||) inside string literals and subexpressions.
function Get-SubCommands {
    param([string]$CommandString)
    $errors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($CommandString, [ref]$tokens, [ref]$errors)
    return $ast, ($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) |
                  ForEach-Object { $_.Extent.Text })
}

# Returns true if all top-level statements are assignments or the list is empty (comments/blank).
function Test-OnlyAssignmentsOrComments {
    param($Ast)
    $statements = $Ast.EndBlock.Statements
    if ($statements.Count -eq 0) { return $true }
    foreach ($stmt in $statements) {
        if ($stmt -isnot [System.Management.Automation.Language.AssignmentStatementAst]) {
            return $false
        }
    }
    return $true
}

# Returns the decision ("allow", "ask", "deny") for a given sub-command against
# an ordered list of rules for the matched tool. Returns $null if no rule matches.
function Get-Decision {
    param([string]$SubCommand, [array]$Rules)
    foreach ($rule in $Rules) {
        $hasPatterns = $rule.PSObject.Properties['commandPattern'] -or $rule.PSObject.Properties['commandPatterns']
        if ($hasPatterns) {
            $patterns = @()
            if ($rule.PSObject.Properties['commandPattern'])  { $patterns += $rule.commandPattern }
            if ($rule.PSObject.Properties['commandPatterns']) { $patterns += $rule.commandPatterns }
            $matched = $false
            foreach ($pattern in $patterns) {
                if ($SubCommand -match $pattern) { $matched = $true; break }
            }
            if (-not $matched) { continue }
        }
        # Rule matches (no patterns = unconditional match)
        if ($rule.PSObject.Properties['decision']) { return $rule.decision }
        return "allow"
    }
    return $null  # No rule matched
}

try {
    $inputData = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $toolName    = $inputData.toolName
    $toolArgsRaw = $inputData.toolArgs

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

    $toolRules = @($config.rules | Where-Object { $_.tool -eq $toolName })

    if ($toolRules.Count -eq 0) {
        @{
            permissionDecision       = "ask"
            permissionDecisionReason = "Copilot wants to use: $toolName"
        } | ConvertTo-Json -Compress
        exit 0
    }

    # For tools with no pattern constraints in any rule, check the first unconditional rule
    $hasAnyPatterns = $toolRules | Where-Object {
        $_.PSObject.Properties['commandPattern'] -or $_.PSObject.Properties['commandPatterns']
    }

    if (-not $hasAnyPatterns) {
        # All rules are unconditional — use the first rule's decision
        $decision = if ($toolRules[0].PSObject.Properties['decision']) { $toolRules[0].decision } else { "allow" }
        if ($decision -eq "allow") { exit 0 }
        @{ permissionDecision = $decision; permissionDecisionReason = "Tool '$toolName' requires approval." } | ConvertTo-Json -Compress
        exit 0
    }

    $toolArgs = $toolArgsRaw | ConvertFrom-Json
    $command  = $toolArgs.command

    $ast, $subCommands = Get-SubCommands $command

    if (-not $subCommands) {
        if (Test-OnlyAssignmentsOrComments $ast) { exit 0 }
        @{
            permissionDecision       = "deny"
            permissionDecisionReason = "Command has no recognizable invocations and is not a simple assignment: $command"
        } | ConvertTo-Json -Compress
        exit 0
    }

    $askSubs = @()
    foreach ($sub in $subCommands) {
        $decision = Get-Decision -SubCommand $sub -Rules $toolRules
        if ($null -eq $decision -or $decision -eq "ask") {
            $askSubs += $sub
        } elseif ($decision -eq "deny") {
            @{
                permissionDecision       = "deny"
                permissionDecisionReason = "Sub-command denied for '$toolName': $sub"
            } | ConvertTo-Json -Compress
            exit 0
        }
    }

    if ($askSubs.Count -gt 0) {
        $subList = $askSubs -join "`n"
        @{
            permissionDecision       = "ask"
            permissionDecisionReason = "Copilot wants to run the following unapproved sub-commands:`n$subList"
        } | ConvertTo-Json -Compress
        exit 0
    }

    exit 0  # All sub-commands allowed

} catch {
    # Fail open on error to avoid blocking legitimate operations
    exit 0
}
