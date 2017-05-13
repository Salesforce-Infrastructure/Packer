$CurtinResult = $null
C:\PackerScripts\PO-ResultObject.ps1
$CurtinResult = Import-Clixml -Path ".\PO-ResultObject.xml"
if (Test-Path "A:\Physical.pac") {
    Copy-Item "C:\PackerScripts\curtin" -Destination "C:\" -Recurse  
}
$CurtinResult.Completed = $true
$CurtinResult.Reboot = $false
$CurtinResult  