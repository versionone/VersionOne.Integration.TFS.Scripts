param (
  $instanceName='VersionOne',
  $version='15.0.0.6469',
  $authMode="V1",
  $dbName='VersionOne'
)
$tempDir = Join-Path $env:TEMP 'VersionOne'
$versionOneSetup = "VersionOne.Setup-Ultimate-$version.exe"
New-Item "$tempDir" -type directory
$url = "https://s3.amazonaws.com/versionone-chocolatey/$versionOneSetup"
$local = Join-Path $tempDir $versionOneSetup
Invoke-WebRequest $url -Outfile $local

$v1Params = @{
  "DbServer" = "(local)";
  "DbName" = $dbName;
  "InstanceName" = $instanceName;
  "LogFile" = Join-Path $tempDir "VersionOneSetup.log";
  "AuthMode" = $authMode;
}

if (!$silentArgs) {  
  Get-ChildItem Env: | Where { $_.Key.ToUpper().StartsWith("V1") } | foreach { 
    $paramName = $_.Key.Substring(2)
    $v1Params[$paramName] = $_.Value
  }
  $silentArgs = "-Quiet"
  foreach ($key in $v1Params.Keys) {
    if ($key -ne "InstanceName") {
      $silentArgs = $silentArgs + " -" + $key + ":'" + $v1Params[$key] + "'"
    }
  }
  $silentArgs = $silentArgs + " " + $v1Params["InstanceName"]
}

$versionone_cmd = "`"$local`" $silentArgs"

Write-Host "$versionone_cmd"

$psi = new-object System.Diagnostics.ProcessStartInfo
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.FileName = $local
$psi.Arguments = "$silentArgs"
if ([Environment]::OSVersion.Version -ge (new-object 'Version' 6,0)){
  $psi.Verb = "runas"
}
$psi.WorkingDirectory = get-location
$s = [System.Diagnostics.Process]::Start($psi)

Write-Host "Finished installing: $instanceName"