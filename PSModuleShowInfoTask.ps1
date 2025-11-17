Add-BuildTask ShowInfo {
    Write-Build Gray
    Write-Build Gray ('Running in:                 {0}' -f $env:BHBuildSystem)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray
    Write-Build Gray ('Project name:               {0}' -f $MODULE_NAME)
    Write-Build Gray ('Project root:               {0}' -f $BuildRoot)
    Write-Build Gray ('Build Path:                 {0}' -f $OUTPUT_ROOT)
    Write-Build Gray ('Module Source Path:         {0}' -f $PSModuleSourcePath)
    Write-Build Gray '-------------------------------------------------------'
    # Write-Build Gray
    # Write-Build Gray ('Branch:                     {0}' -f $env:BHBranchName)
    # Write-Build Gray ('Commit:                     {0}' -f $env:BHCommitMessage)
    # Write-Build Gray ('Build #:                    {0}' -f $env:BHBuildNumber)
    # Write-Build Gray ('Next Version:               {0}' -f $SemVer)
    # Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray
    Write-Build Gray ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString())
    Write-Build Gray ('OS:                         {0}' -f $OS)
    Write-Build Gray ('OS Version:                 {0}' -f $OSVersion)
    Write-Build Gray
}