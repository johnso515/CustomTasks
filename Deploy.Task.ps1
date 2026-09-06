<#
    Deploy the built module, but only after PSModuleDeployGuard has confirmed the artifact is not
    older than its source.

    Wiring the guard in HERE rather than asking every repo to remember it is the whole point: a
    check that has to be invoked deliberately protects only the runs where someone already
    suspected a problem, which are never the runs that need it. Stale deploys are found by
    accident precisely because nothing refuses them.

    CustomTasks is copied into /Tasks after the poshcode set (see the Earthfile), so a task defined
    here wins on name conflict. If poshcode/tasks ever grows its own Deploy that does more than
    PSDeploy - a gallery publish, say - this REPLACES it rather than wrapping it. There is no
    Deploy task in the shared set today; revisit if one appears.

    The guard runs as the first job, so a stale artifact throws before PSDeploy is ever reached.
#>
Add-BuildTask Deploy PSModuleDeployGuard, {
    $InformationPreference = 'Continue'

    $manifest = Get-ChildItem -Path $BuildRoot -Filter '*.psdeploy.ps1' -File -ErrorAction Ignore |
        Select-Object -First 1

    if (-not $manifest) {
        Write-Warning "Deploy: no *.psdeploy.ps1 in $BuildRoot - nothing to deploy."
        return
    }

    if (-not (Get-Module -ListAvailable PSDeploy -ErrorAction Ignore)) {
        throw "Deploy: PSDeploy is not installed, cannot run $($manifest.Name)."
    }

    Write-Information "Deploy: $($manifest.Name)"
    Invoke-PSDeploy -Path $manifest.FullName -Force -ErrorAction Stop
}
