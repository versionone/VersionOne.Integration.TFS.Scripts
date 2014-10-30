#servicetfs20132.cloudapp.net
Param(
    $azure_service_name="servicetfs20132",
    $Url="https://www14.v1host.com/v1sdktesting/",
    $UserName="",
    $Password="",
    $TfsUrl="http://$azure_service_name.cloudapp.net:8080/tfs/DefaultCollection/",
    $TfsUser="",
    $TfsPassword="",
    $IsWindowsIntegratedSecurity="False",
    $DebugMode="True",
    $TfsWorkItemRegex="[A-Z]{1,2}-[0-9]+",
    $ProxyIsEnabled="False",
    $ProxyUrl="",
    $ProxyUserName="",
    $ProxyPassword="",
    $ProxyDomain="",
    $BaseListenerUrl="http://$azure_service_name.cloudapp.net:9090/",
    $tfs_listener_url = "http://$azure_service_name.cloudapp.net:9090/service.svc",
    $tfs_team_project_collection = "http://$azure_service_name.cloudapp.net:8080/tfs",
    $tfs_event_tag = "VersionOneTFSServer"
)

$file =((${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0])+"\VersionOne\TFSListener\web\App_Data\settings.ini"

$content="V1_Url|$Url
V1_Password|$Password
V1_UserName|$UserName
V1_TfsUrl|$TfsUrl
V1_TfsUser|$TfsUser
V1_TfsPassword|$TfsPassword
V1_IsWindowsIntegratedSecurity|$IsWindowsIntegratedSecurity
V1_DebugMode|$DebugMode
V1_TfsWorkItemRegex|$TfsWorkItemRegex
V1_ProxyIsEnabled|$ProxyIsEnabled
V1_ProxyUrl|$ProxyUrl
V1_ProxyUserName|$ProxyUserName
V1_ProxyPassword|$ProxyPassword
V1_ProxyDomain|$ProxyDomain
V1_BaseListenerUrl|$BaseListenerUrl"

$tfs_core = ((${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0])+"\VersionOne\TFSListener\VersionOne.Integration.Tfs.Core.dll"

Add-Type -Path $tfs_core
$protected_content = [VersionOne.Integration.Tfs.Core.Security.ProtectData]::Protect($content)

write-host "Writing settings file"
out-file -filepath "$file" -inputobject $protected_content -encoding UTF8

$tfs_computer_name = "$env:computername"
$local_path = "Temp - $tfs_computer_name"
$tfs_local_path = "C:\\$local_path"
$tfs_automation_remote = "https://portalvhdsw36vjbsgqb26p.blob.core.windows.net/installers/Automation.Tfs.exe"
$tfs_automation = "$tfs_local_path\\Automation.Tfs.exe"

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

$key="Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
Set-itemProperty $key BackConnectionHostNames -value "$azure_service_name.cloudapp.net" -type MultiString

write-host "Attaching events: CheckinEvent,BuildCompletionEvent2"
$events_cmd = "`"$tfs_automation`" Subscribe -tfsTeamProjectCollection='$tfs_team_project_collection' -listener='$tfs_listener_url' -tfsEvent='CheckinEvent,BuildCompletionEvent2' -eventTag='$tfs_event_tag'"
iex "& $events_cmd"