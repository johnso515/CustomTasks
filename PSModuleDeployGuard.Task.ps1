<#
    Refuse to deploy a module whose built artifact is older than its source.

    Stale artifacts are the most expensive cheap bug in this estate: a module whose source has
    moved on from its build behaves exactly like a broken fix - the code is right, the change is
    committed, and the running behaviour is the old one. Three modules hit this in a single
    session (2026-09-05/06) and each cost a full debugging cycle before anyone thought to check a
    timestamp. A deploy that silently copies a stale build is the step that makes that possible,
    so this is the step that should refuse.

    Usage - gate a deploy by making this a dependency, or run it on its own:

        Invoke-Build PSModuleDeployGuard
        Add-BuildTask Deploy PSModuleDeployGuard, { ... }

    FAILS only on a PROVEN stale artifact: source committed more recently than the built .psm1.
    Everything it cannot establish - no git, no history, no build yet - is a warning, because a
    guard that blocks on its own uncertainty gets switched off, and then guards nothing.

    Uncommitted source edits are reported but never fail the task. That is the normal state
    mid-change, and failing on it would make the guard unusable exactly when someone is working.
#>
Add-BuildTask PSModuleDeployGuard {
    $InformationPreference = 'Continue'

    # These come from the shared task initialisation. Fall back to the layout convention so the
    # task still works when invoked directly in a repo that has not run _Initialize.
    $moduleName = if ($PSModuleName) { $PSModuleName } else { Split-Path $BuildRoot -Leaf }
    $sourceRoot = if ($PSModuleSourceRoot) { $PSModuleSourceRoot } else { Join-Path $BuildRoot $moduleName }

    $built = Get-ChildItem -Path (Join-Path $BuildRoot "Modules/$moduleName") `
        -Filter "$moduleName.psm1" -Recurse -File -ErrorAction Ignore |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $built) {
        Write-Warning "PSModuleDeployGuard: no built '$moduleName.psm1' found under Modules/$moduleName - nothing to verify."
        return
    }

    <#
        Source currency is measured from the newest COMMIT, not from file mtimes. A checkout, a
        branch switch or a stash pop rewrites mtimes wholesale and would condemn a perfectly good
        build.
    #>
    $paths = @("$moduleName/Source", "$moduleName/Configs")
    $stamp = & git -C $BuildRoot log -1 --format=%ct -- @paths 2>$null

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($stamp)) {
        Write-Warning "PSModuleDeployGuard: no git history for $($paths -join ' or ') - cannot verify '$moduleName'."
        return
    }

    $srcCommit = [DateTimeOffset]::FromUnixTimeSeconds([long]$stamp).LocalDateTime

    $dirty = & git -C $BuildRoot status --porcelain -- @paths 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($dirty -join ''))) {
        Write-Warning "PSModuleDeployGuard: '$moduleName' has uncommitted source edits - deploying the last build of what IS committed."
    }

    if ($srcCommit -gt $built.LastWriteTime) {
        $msg = @(
            "PSModuleDeployGuard: '$moduleName' would deploy a STALE build - refusing."
            "  newest source commit : $($srcCommit.ToString('yyyy-MM-dd HH:mm:ss'))"
            "  built artifact       : $($built.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))  ($($built.FullName))"
            ''
            '  Rebuild before deploying. Deploying now would copy code older than the committed'
            '  source, which presents as "the fix did not work" rather than as any error.'
        ) -join [Environment]::NewLine
        throw $msg
    }

    Write-Information "PSModuleDeployGuard: '$moduleName' is current (built $($built.LastWriteTime.ToString('MM-dd HH:mm')), newest source commit $($srcCommit.ToString('MM-dd HH:mm')))."
}
