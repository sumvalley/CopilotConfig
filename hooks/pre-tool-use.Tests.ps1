BeforeAll {
    $script:HookScript = Join-Path $PSScriptRoot "pre-tool-use.ps1"

    function Invoke-Hook {
        param(
            [string]$ToolName,
            [hashtable]$ToolArgs = @{},
            [object[]]$Rules
        )
        $tempConfig = [System.IO.Path]::GetTempFileName()
        try {
            @{ rules = $Rules } | ConvertTo-Json -Depth 5 | Set-Content $tempConfig

            $toolArgsJson  = $ToolArgs | ConvertTo-Json -Compress
            $inputJson = @{ toolName = $ToolName; toolArgs = $toolArgsJson } | ConvertTo-Json -Compress

            $output = $inputJson | pwsh -NoProfile -File $script:HookScript -ConfigPath $tempConfig
            if ($output) { return $output | ConvertFrom-Json }
            return $null  # No output = allow
        } finally {
            Remove-Item $tempConfig -ErrorAction SilentlyContinue
        }
    }
}

Describe "pre-tool-use hook" {

    Describe "tool not in allowlist" {
        It "returns ask with tool name when tool is unknown" {
            $result = Invoke-Hook -ToolName "unknown-tool" -Rules @()
            $result.permissionDecision | Should -Be "ask"
            $result.permissionDecisionReason | Should -BeLike "*unknown-tool*"
        }
    }

    Describe "tool in allowlist without patterns" {
        It "allows unconditionally when no decision is specified" {
            $result = Invoke-Hook -ToolName "view" -Rules @(
                @{ tool = "view" }
            )
            $result | Should -BeNullOrEmpty
        }

        It "allows when decision is allow" {
            $result = Invoke-Hook -ToolName "view" -Rules @(
                @{ tool = "view"; decision = "allow" }
            )
            $result | Should -BeNullOrEmpty
        }

        It "asks when decision is ask" {
            $result = Invoke-Hook -ToolName "view" -Rules @(
                @{ tool = "view"; decision = "ask" }
            )
            $result.permissionDecision | Should -Be "ask"
        }

        It "denies when decision is deny" {
            $result = Invoke-Hook -ToolName "view" -Rules @(
                @{ tool = "view"; decision = "deny" }
            )
            $result.permissionDecision | Should -Be "deny"
        }
    }

    Describe "tool with commandPatterns" {
        BeforeAll {
            $script:rules = @(@{ tool = "powershell"; commandPatterns = @("^git ", "^dotnet build") })
        }

        It "allows when command matches a pattern" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "git status" } -Rules $script:rules
            $result | Should -BeNullOrEmpty
        }

        It "allows when command matches second pattern" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "dotnet build ." } -Rules $script:rules
            $result | Should -BeNullOrEmpty
        }

        It "asks when command does not match any pattern" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "Remove-Item foo.txt" } -Rules $script:rules
            $result.permissionDecision | Should -Be "ask"
            $result.permissionDecisionReason | Should -BeLike "*Remove-Item foo.txt*"
        }
    }

    Describe "multiple rules per tool — first match wins" {
        BeforeAll {
            $script:multiRules = @(
                @{ tool = "powershell"; commandPatterns = @("^git ");        decision = "allow" },
                @{ tool = "powershell"; commandPatterns = @("^Remove-Item"); decision = "ask"   },
                @{ tool = "powershell"; commandPatterns = @("^Format-");     decision = "deny"  }
            )
        }

        It "allows git commands" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "git status" } -Rules $script:multiRules
            $result | Should -BeNullOrEmpty
        }

        It "asks for Remove-Item" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "Remove-Item foo.txt" } -Rules $script:multiRules
            $result.permissionDecision | Should -Be "ask"
        }

        It "denies Format- commands" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "Format-Volume C:" } -Rules $script:multiRules
            $result.permissionDecision | Should -Be "deny"
        }
    }

    Describe "compound commands" {
        BeforeAll {
            $script:compoundRules = @(
                @{ tool = "powershell"; commandPatterns = @("^git ", "^dotnet build", "^Select-String"); decision = "allow" },
                @{ tool = "powershell"; commandPatterns = @("^Remove-Item"); decision = "ask" }
            )
        }

        It "allows when all sub-commands match" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "git status | Select-String warning" } -Rules $script:compoundRules
            $result | Should -BeNullOrEmpty
        }

        It "asks when one sub-command is unknown" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "git status && Write-Host done" } -Rules $script:compoundRules
            $result.permissionDecision | Should -Be "ask"
            $result.permissionDecisionReason | Should -BeLike "*Write-Host done*"
        }

        It "lists all unknown sub-commands when multiple are unrecognized" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "Write-Host a && Write-Host b" } -Rules $script:compoundRules
            $result.permissionDecision | Should -Be "ask"
            $result.permissionDecisionReason | Should -BeLike "*Write-Host a*"
            $result.permissionDecisionReason | Should -BeLike "*Write-Host b*"
        }

        It "asks when one sub-command matches an ask rule" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "git status && Remove-Item foo.txt" } -Rules $script:compoundRules
            $result.permissionDecision | Should -Be "ask"
        }

        It "denies when one sub-command matches a deny rule even in a pipeline" {
            $denyRules = @(
                @{ tool = "powershell"; commandPatterns = @("^git "); decision = "allow" },
                @{ tool = "powershell"; commandPatterns = @("^Format-"); decision = "deny" }
            )
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "git status && Format-Volume C:" } -Rules $denyRules
            $result.permissionDecision | Should -Be "deny"
        }

        It "semicolon-separated commands are each checked independently" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "git status; Write-Host done" } -Rules $script:compoundRules
            $result.permissionDecision | Should -Be "ask"
        }
    }

    Describe "assignments and comments" {
        BeforeAll {
            $script:assignRules = @(@{ tool = "powershell"; commandPatterns = @("^git ") })
        }

        It "allows pure variable assignments" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = '$x = 1' } -Rules $script:assignRules
            $result | Should -BeNullOrEmpty
        }

        It "allows comment-only input" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = "# just a comment" } -Rules $script:assignRules
            $result | Should -BeNullOrEmpty
        }

        It "checks the command in an assignment+command compound" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = '$f = "file.txt"; Remove-Item $f' } -Rules $script:assignRules
            $result.permissionDecision | Should -Be "ask"
        }

        It "does not split on semicolons inside string literals" {
            $result = Invoke-Hook -ToolName "powershell" -ToolArgs @{ command = 'git commit -m "fix: update; refactor"' } -Rules $script:assignRules
            $result | Should -BeNullOrEmpty
        }
    }
}
