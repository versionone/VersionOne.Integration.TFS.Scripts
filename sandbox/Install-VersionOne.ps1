param (
  $instanceName,
  $authMode,
  $dbName
)

$params = "-Quiet:2 -DbName:$dbName -DbServer:(local) -AuthMode:$authMode -LogFile:$instanceName.log $instanceName"

Write-Host "With: $params"

cinst VersionOne -source https://www.myget.org/F/versionone/ -installArgs $params -override -force

Write-Host "Finished installing: $instanceName"