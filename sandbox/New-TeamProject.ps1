param (
    $CollectionUri = "http://localhost:8080/tfs/DefaultCollection",
    $ProjectName = "AnotherTeamProject",
    $ProcessTemplateName = "MSF for Agile Software Development 2013"
)
 
if (-not $Env:TFSPowerToolDir) {
     Invoke-Reboot
}
 
$TfptExe = Join-Path -Path $Env:TFSPowerToolDir -ChildPath tfpt.exe
if (-not (Test-Path -Path $TfptExe -PathType Leaf)) {
throw 'Team Foundation Server Power Tools must be installed.'
}
 
if (Get-Process | Where-Object { $_.Name -eq 'devenv' }) {
Stop-Process -Name 'devenv'
}
 
$WorkingPath = Join-Path -Path $Env:TEMP -ChildPath ([Guid]::NewGuid())
New-Item -Path $WorkingPath -ItemType Container | Out-Null
 
$XmlDoc = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="ProjectCreationSettingsFileSchema.xsd">
<TFSName>placeholder</TFSName>
<LogFolder>placeholder</LogFolder>
<ProjectName>placeholder</ProjectName>
<ProjectReportsEnabled>false</ProjectReportsEnabled>
<ProjectSiteEnabled>false</ProjectSiteEnabled>
<ProjectSiteTitle>placeholder</ProjectSiteTitle>
<SccCreateType>New</SccCreateType>
<ProcessTemplateName>placeholder</ProcessTemplateName>
</Project>
"@
 
$XmlDoc.Project.TFSName = $CollectionUri
$XmlDoc.Project.LogFolder = [string]$WorkingPath
$XmlDoc.Project.ProjectName = $ProjectName
$XmlDoc.Project.ProjectSiteTitle = $ProjectName
$XmlDoc.Project.ProcessTemplateName = $ProcessTemplateName
$XmlDoc.Save("$WorkingPath\settings.xml")

Write-Host "Creating Team Project..." 
& $TfptExe createteamproject /settingsfile:"$WorkingPath\settings.xml" 2>&1 |
Tee-Object -Variable ExeResult
$TfptExitCode = $LASTEXITCODE
$LogResult = $WorkingPath | Get-ChildItem -Exclude settings.xml | Get-Content
 
if ($ExeResult -is [System.Management.Automation.ErrorRecord]) {
    throw "Failed to create new team project:`n$ExeResult"
}
 
if ($TfptExitCode -or $LogResult -match 'exception') {
    Write-Host "Failed to create new team project:`n$LogResult"
    Write-Host "Trying again..."
    Write-Host "Killing devenv"
    Stop-Process -Name 'devenv'
    Write-Host "Creating Team Project again..."
    & $TfptExe createteamproject /settingsfile:"$WorkingPath\settings.xml" 2>&1 |
    Tee-Object -Variable ExeResult
    $TfptExitCode = $LASTEXITCODE
}

Remove-Item -Path $WorkingPath -Force -Recurse

"Project created."