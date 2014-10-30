param (
    $tfs_team_project_collection = "http://localhost:8080/tfs",
    $tfs_team_project = "AnotherTeamProject",
    $tfs_build_name = "Another Build",
    $tfs_build_description = "Build description.",
    $tfs_workspace = "AnotherWorkspace",
    $tfs_git_repository = "https://github.com/lremedi/Automation.Tfs",
    $tfs_automation_remote = "https://portalvhdsw36vjbsgqb26p.blob.core.windows.net/installers/Automation.Tfs.exe"
)

$tfs_computer_name = "$env:computername"
$local_path = "Temp - $tfs_computer_name"
$tfs_local_path = "C:\$local_path"
$tfs_automation = "$tfs_local_path\Automation.Tfs.exe"

Remove-Item -Recurse -Force $tfs_local_path
 
Write-Host "Getting git full path"
$git_path = (Get-ChildItem -path $env:systemdrive\ -filter "git.exe" -erroraction silentlycontinue -recurse)[0].FullName
$tfs_git_repository = "https://github.com/lremedi/Automation.Tfs"
$GitExe = $git_path -f $env:SystemDrive;
$ArgumentList = "clone $tfs_git_repository `"$tfs_local_path`""
Write-Host "Cloning $tfs_git_repository to $tfs_local_path for sample data"
Start-Process -FilePath $GitExe -ArgumentList $ArgumentList -Wait -NoNewWindow
Remove-Item -path $tfs_local_path\.git -force -Recurse

if(-not (Test-Path $tfs_local_path)) {
    Write-Host "Creating temp folder..."
    mkdir $tfs_local_path 
}

if (Test-Path $tfs_automation){
    write-Host "Removing existing TFS automation tool ..."
    Remove-Item $tfs_automation
}
 
Write-Host "Getting V1 Tfs Automation Tool"
Invoke-WebRequest $tfs_automation_remote -OutFile $tfs_automation
 
write-host "Checking In Sample Code with Tfs Automation Tool"
$checkin_cmd = "`"$tfs_automation`" CheckInFolder -tfsTeamProjectCollection='$tfs_team_project_collection' -teamProject='$tfs_team_project' -workspaceName='$tfs_workspace' -localDir='$tfs_local_path'"
iex "& $checkin_cmd"
 
write-host "Configuring build with Tfs Automation Tool"
$build_cmd = "`"$tfs_automation`" BuildDefinition -tfsTeamProjectCollection='$tfs_team_project_collection' -teamProject='$tfs_team_project' -buildController='$tfs_computer_name - Controller' -buildName='$tfs_build_name' -buildDescription='$tfs_build_description'"
iex "& $build_cmd"