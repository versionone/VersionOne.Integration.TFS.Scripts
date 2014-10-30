param (
    $tfs_listener_remote = "https://portalvhdsw36vjbsgqb26p.blob.core.windows.net/installers/VersionOne.TFSListener.Installer.msi"
)
$tfs_computer_name = "$env:computername"
$local_path = "Temp - $tfs_computer_name"
$tfs_local_path = "C:\$local_path"

$tfs_listener = "$tfs_local_path\VersionOne.TFSListener.Installer.msi"
$tfs_listener_log = "$tfs_local_path\VersionOne.TFSListener.Installer.log"

if(-not (Test-Path $tfs_local_path)) {
    Write-Host "Creating temp folder..."
    mkdir $tfs_local_path 
}

if (Test-Path $tfs_listener){
    write-Host "Removing existing TFS Listener installer ..."
    Remove-Item $tfs_listener
}

if (Test-Path $tfs_listener_log){
    write-Host "Removing existing TFS Listener installation log ..."
    Remove-Item $tfs_listener_log
}
Invoke-WebRequest $tfs_listener_remote -OutFile $tfs_listener
write-Host "Installing TFS Listener..."
iex "& msiexec /i '$tfs_listener' /qn /norestart /L '$tfs_listener_log'"
write-Host "Log file: $tfs_listener_log"

write-Host "Adding Tfs Listener Firewall Rules"
New-NetFirewallRule -DisplayName "Tfs Listener 9090" -Direction Outbound -LocalPort 9090 -Protocol TCP -Action Allow -Profile Public
New-NetFirewallRule -DisplayName "Tfs Listener 9090" -Direction Inbound -LocalPort 9090 -Protocol TCP -Action Allow -Profile Public