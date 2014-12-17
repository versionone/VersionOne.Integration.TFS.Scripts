Param(
    [string]$vm_username="v1deploy",
    [string]$vm_password="Versi0n1.c26nu",
    [string]$vm_name="tfs2013vm",
    [string]$new="true",
    [string]$install_tfs="true",
    [string]$install_versionone="false",
    [string]$install_tfs_sampledata="true",
    [string]$install_tfs_integration="false"
)

Write-Host "Starting execution at:"(Get-Date -Format g)

Write-Host "vm_username: $vm_username"
Write-Host "vm_password: $vm_password"
Write-Host "vm_name: $vm_name"
Write-Host "new: $new"
Write-Host "install_versionone: $install_versionone"
Write-Host "install_tfs_sampledata: $install_tfs_sampledata"
Write-Host "install_tfs_integration: $install_tfs_integration"

$secpasswd = ConvertTo-SecureString $vm_password -AsPlainText -Force
$cred=New-Object System.Management.Automation.PSCredential ($vm_username, $secpasswd)

$script_path_step1 = 'Install-Tfs.ps1'
$script_path_step2 = 'Install-VersionOne.ps1'
$script_path_step3 = 'New-TeamProject.ps1'
$script_path_step4 = 'New-SampleData.ps1'
$script_path_step5 = 'Install-TfsListener.ps1'
$script_path_step6 = 'Configure-TfsListener.ps1'

if ($new -eq "true"){
    $image_name = "sqlvstemplate"
    Write-Host 'Removing previous VM'
    Remove-AzureVM -ServiceName $vm_name -Name $vm_name -DeleteVHD
    Remove-AzureService -ServiceName $vm_name -Force
 
    Write-Host 'Spinning New Azure VM'
    New-AzureQuickVM -ServiceName $vm_name -Windows -Name $vm_name -ImageName $image_name -Password $cred.GetNetworkCredential().Password -AdminUsername $cred.UserName -InstanceSize Medium -Location "South Central US" -WaitForBoot

    Write-Host 'Adding Azure End Point 8080 for TFS'
    Get-AzureVM -ServiceName $vm_name -Name $vm_name | Add-AzureEndpoint -Name "TFS" -Protocol "tcp" -PublicPort 8080 -LocalPort 8080 | Update-AzureVM

    Write-Host 'Adding Azure End Point 9090 for Tfs Listener'
    Get-AzureVM -ServiceName $vm_name -Name $vm_name | Add-AzureEndpoint -Name "TfsListener" -Protocol "tcp" -PublicPort 9090 -LocalPort 9090 | Update-AzureVM
}

if($install_tfs -eq "true"){
    Write-Host "Installing Tfs..."
    #$script_path_step1 = 'Install-Tfs.ps1'
    Invoke-RmtAzure "$vm_username" "$vm_password" "$vm_name" "$vm_name" "$script_path_step1"

    $boxstarterVM = Enable-BoxstarterVM -Provider azure -CloudServiceName $vm_name -VMName $vm_name -Credential $cred
    $boxstarterVM | Install-BoxstarterPackage -Package git -Credential $cred
    $boxstarterVM | Install-BoxstarterPackage -Package tfs2013powertools -Credential $cred

    Write-Host "Restarting VM after tool installation..."
    Restart-AzureVM -ServiceName $vm_name -Name $vm_name

    # Wait for server to reboot
    $VMStatus = Get-AzureVM -ServiceName $vm_name -name $vm_name
     
    While ($VMStatus.InstanceStatus -ne "ReadyRole")
    {
      write-host "Waiting...Current Status = " $VMStatus.Status
      Start-Sleep -Seconds 15
     
      $VMStatus = Get-AzureVM -ServiceName $vm_name -name $vm_name
    }
}

if ($install_versionone -eq "true")
{
    Write-Host "Installing VersionOne..."
    #$script_path_step2 = 'Install-VersionOne.ps1'
    Write-Host "Restarting VM"
    Restart-AzureVM -ServiceName $vm_name -Name $vm_name

    # Wait for server to reboot
    $VMStatus = Get-AzureVM -ServiceName $vm_name -name $vm_name
     
    While ($VMStatus.InstanceStatus -ne "ReadyRole")
    {
      write-host "Waiting...Current Status = " $VMStatus.Status
      Start-Sleep -Seconds 15
     
      $VMStatus = Get-AzureVM -ServiceName $vm_name -name $vm_name
    }

    Write-Host 'Adding Azure End Point 80 for HTTP'
    Get-AzureVM -ServiceName $vm_name -Name $vm_name | Add-AzureEndpoint -Name "HTTP" -Protocol "tcp" -PublicPort 80 -LocalPort 80 | Update-AzureVM


    Invoke-RmtAzure "$vm_username" "$vm_password" "$vm_name" "$vm_name" "$script_path_step2"
}

if ($install_tfs_sampledata -eq "true"){
    Write-Host "Setting sample data..."
    #$script_path_step3 = 'New-TeamProject.ps1'
    $CollectionUri = "http://localhost:8080/tfs/DefaultCollection"
    $ProjectName = "AnotherTeamProject"
    $ProcessTemplateName = "MSF for Agile Software Development 2013.4"
    Invoke-RmtAzure "$vm_username" "$vm_password" "$vm_name" "$vm_name" "$script_path_step3" `
    @($CollectionUri,$ProjectName,$ProcessTemplateName)

    #$script_path_step4 = 'New-SampleData.ps1'
    $tfs_team_project_collection = "http://localhost:8080/tfs"
    $tfs_team_project = "AnotherTeamProject"
    $tfs_build_name = "Another Build"
    $tfs_build_description = "Build description."
    $tfs_workspace = "AnotherWorkspace"
    $tfs_git_repository = "https://github.com/lremedi/Automation.Tfs"
    $tfs_automation_remote = "https://portalvhdsw36vjbsgqb26p.blob.core.windows.net/installers/Automation.Tfs.exe"
    Invoke-RmtAzure "$vm_username" "$vm_password" "$vm_name" "$vm_name" "$script_path_step4" `
    @($tfs_team_project_collection,$tfs_team_project, $tfs_build_name, $tfs_build_description, $tfs_workspace, $tfs_git_repository, $tfs_automation_remote)
}

if ($install_tfs_integration -eq "true"){
    #$script_path_step5 = 'Install-TfsListener.ps1'
    $tfs_listener_remote = "https://v1integrations.blob.core.windows.net/downloads/VersionOne.Integration.Tfs.Listener.Installer.msi"
    Invoke-RmtAzure "$vm_username" "$vm_password" "$vm_name" "$vm_name" "$script_path_step5" `
    @($tfs_listener_remote)

    #$script_path_step6 = 'Configure-TfsListener.ps1'
    $Url="https://www14.v1host.com/v1sdktesting/"
    $UserName="admin"
    $Password="admin"
    $TfsUrl="http://$vm_name.cloudapp.net:8080/tfs/DefaultCollection/"
    Invoke-RmtAzure "$vm_username" "$vm_password" "$vm_name" "$vm_name" "$script_path_step6" `
    @($vm_name,$Url,$UserName,$Password,$TfsUrl,$vm_username,$vm_password)
}

Write-Host "Ending execution at:"(Get-Date -Format g)