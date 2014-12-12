Param(
    [string]$vm_username,
    [string]$vm_password,
    [string]$vm_name,
    [string]$azure_service_name,
    [string]$new,
    [string]$install_tfs_integration
)

Write-Host "Starting execution at:"(Get-Date -Format g)

$secpasswd = ConvertTo-SecureString $vm_password -AsPlainText -Force
$cred=New-Object System.Management.Automation.PSCredential ($vm_username, $secpasswd)

if ($new -eq "true"){
    #$image_name = "sql2012exp-20140925-13769"
    $image_name = "sqlftstemplate-202605-71354"
    Write-Host 'Removing previous VM'
    Remove-AzureVM -ServiceName $azure_service_name -Name $vm_name -DeleteVHD
    Remove-AzureService -ServiceName $azure_service_name -Force
 
    Write-Host 'Spinning New Azure VM'
    New-AzureQuickVM -ServiceName $azure_service_name -Windows -Name $vm_name -ImageName $image_name -Password $cred.GetNetworkCredential().Password -AdminUsername $cred.UserName -InstanceSize Medium -Location "North Europe" -WaitForBoot

    Write-Host 'Adding Azure End Point 8080 for TFS'
    Get-AzureVM -ServiceName $azure_service_name -Name $vm_name | Add-AzureEndpoint -Name "TFS" -Protocol "tcp" -PublicPort 8080 -LocalPort 8080 | Update-AzureVM

    Write-Host 'Adding Azure End Point 9090 for Tfs Listener'
    Get-AzureVM -ServiceName $azure_service_name -Name $vm_name | Add-AzureEndpoint -Name "TfsListener" -Protocol "tcp" -PublicPort 9090 -LocalPort 9090 | Update-AzureVM
}

$script_path_step1 = 'New-TeamProject.ps1'
$script_path_step2 = 'New-SampleData.ps1'
$script_path_step3 = 'Install-TfsListener.ps1'
$script_path_step4 = 'Configure-TfsListener.ps1'

$boxstarterVM = Enable-BoxstarterVM -Provider azure -CloudServiceName $azure_service_name -VMName $vm_name -Credential $cred
$boxstarterVM | Install-BoxstarterPackage -Package tfsexpress.standard -Credential $cred
$boxstarterVM | Install-BoxstarterPackage -Package tfsexpress.build -Credential $cred
$boxstarterVM | Install-BoxstarterPackage -Package visualstudiocommunity2013  -Credential $cred
$boxstarterVM | Install-BoxstarterPackage -Package git -Credential $cred
$boxstarterVM | Install-BoxstarterPackage -Package tfs2013powertools -Credential $cred

Write-Host "Restarting VM after tool installation..."
Restart-AzureVM -ServiceName $azure_service_name -Name $vm_name

Write-Host "Setting sample data..."
#$script_path_step1 = 'New-TeamProject.ps1'
$CollectionUri = "http://localhost:8080/tfs/DefaultCollection"
$ProjectName = "AnotherTeamProject"
$ProcessTemplateName = "MSF for Agile Software Development 2013.4"
Invoke-RmtAzure "$vm_username" "$vm_password" "$vm_name" "$azure_service_name" "$script_path_step1" `
@($CollectionUri,$ProjectName,$ProcessTemplateName)

#$script_path_step2 = 'New-SampleData.ps1'
$tfs_team_project_collection = "http://localhost:8080/tfs"
$tfs_team_project = "AnotherTeamProject"
$tfs_build_name = "Another Build"
$tfs_build_description = "Build description."
$tfs_workspace = "AnotherWorkspace"
$tfs_git_repository = "https://github.com/lremedi/Automation.Tfs"
$tfs_automation_remote = "https://portalvhdsw36vjbsgqb26p.blob.core.windows.net/installers/Automation.Tfs.exe"
Invoke-RmtAzure "$vm_username" "$vm_password" "$vm_name" "$azure_service_name" "$script_path_step2" `
@($tfs_team_project_collection,$tfs_team_project, $tfs_build_name, $tfs_build_description, $tfs_workspace, $tfs_git_repository, $tfs_automation_remote)

if ($install_tfs_integration -eq "true"){
    #$script_path_step3 = 'Install-TfsListener.ps1'
    $tfs_listener_remote = "https://v1integrations.blob.core.windows.net/downloads/VersionOne.Integration.Tfs.Listener.Installer.msi"
    Invoke-RmtAzure "$vm_username" "$vm_password" "$vm_name" "$azure_service_name" "$script_path_step3" `
    @($tfs_listener_remote)

    #$script_path_step4 = 'Configure-TfsListener.ps1'
    $Url="https://www14.v1host.com/v1sdktesting/"
    $UserName="remote"
    $Password="remote"
    $TfsUrl="http://$azure_service_name.cloudapp.net:8080/tfs/DefaultCollection/"
    Invoke-RmtAzure "$vm_username" "$vm_password" "$vm_name" "$azure_service_name" "$script_path_step4" `
    @($azure_service_name,$Url,$UserName,$Password,$TfsUrl,$vm_username,$vm_password)
}

Write-Host "Ending execution at:"(Get-Date -Format g)