Add-BuildTask PSModuleBuild @{
    If      = $PSModuleSourcePath
    Inputs  = { Get-ChildItem -Path $PSModuleSourceRoot -Recurse -Filter *.ps* }
    Outputs = { Join-Path $OutputRoot $PSModuleName "$PSModuleName.psm1" } # don't take off the script block, need to resolve AFTER init
    Jobs    = "PSModuleRestore", "GitVersion", {
        $InformationPreference = "Continue"

        $SemVer = $GitVersion.$PSModuleName.InformationalVersion

        $SourcePathsToBuild = @(
            "[Ee]num", "[Cc]lasses", "[Pp]rivate", "[Pp]ublic", "[Vv]iews"
        )
        Write-Information "Build-Module -SourcePath $PSModuleSourcePath -SourceDirectories $SourcePathsToBuild -Destination $PSModuleOutputPath -SemVer $SemVer"
        $Module = Build-Module -SourcePath $PSModuleSourcePath -SourceDirectories $SourcePathsToBuild -Destination $PSModuleOutputPath -SemVer $SemVer -Verbose:$Verbose -Debug:$Debug -Passthru

        if ($DotNetPublishRoot -and (Test-Path $DotNetPublishRoot)) {
            $Libraries = New-Item (Join-Path $Module.ModuleBase lib) -Type Directory -Force | Convert-Path
            Get-ChildItem $DotNetPublishRoot
            | Where-Object { $_.BaseName -notmatch "System.*" -and $_.Extension -notin ".nupkg" }
            | Copy-Item -Destination $Libraries -Recurse
        }
    }
}
