# PSModuleDeployLocal.Task.ps1 - Deploy built PS module to local PSModulePath

# Requires PSModuleName (set in _Initialize.ps1)
if (-not $script:PSModuleName) { throw "No PowerShell module detected. Run after module detection." }

# Depends on PSModuleBuild (via Build) to ensure output exists
task Deploy-Local PSModuleBuild {
    # Dynamic target: First entry in PSModulePath (system-wide; e.g., /usr/local/share/powershell/Modules)
    $modulePaths = $env:PSModulePath -split [IO.Path]::PathSeparator
    if ($modulePaths.Count -eq 0) { throw "PSModulePath is empty or malformed." }
    $targetRoot = $modulePaths[0].Trim()
    $targetPath = Join-Path $targetRoot $script:PSModuleName

    $sourcePath = $script:PSModuleOutputPath
    if (-not (Test-Path $sourcePath -PathType Container)) { throw "Built module missing: $sourcePath (run Build first)" }

    Write-Information "Deploying $script:PSModuleName from $sourcePath to $targetPath"

    # Clean existing installation
    if (Test-Path $targetPath) {
        Write-Host "Removing existing $script:PSModuleName at $targetPath" -ForegroundColor Yellow
        Remove-Item $targetPath -Recurse -Force -ErrorAction Stop
    }

    # Recursive copy (preserves standard structure: .psd1, Public/, etc.)
    Copy-Item $sourcePath $targetRoot -Recurse -Force -ErrorAction Stop

    # Verify: Import and check for commands
    Write-Host "Verifying deployment..." -ForegroundColor Green
    Import-Module $targetPath -Force -ErrorAction Stop
    $commands = Get-Command -Module $script:PSModuleName -ErrorAction SilentlyContinue
    if ($commands.Count -eq 0) {
        throw "Deployment failed: No commands found in $script:PSModuleName after import."
    }
    Write-Information "Deployed successfully. Found $($commands.Count) commands in $script:PSModuleName."
}