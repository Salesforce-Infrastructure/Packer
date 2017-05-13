$CBCResult = $null
C:\PackerScripts\PO-ResultObject.ps1
$CBCResult = Import-Clixml -Path ".\PO-ResultObject.xml"
Write-Output "Attempting to instal Chocolatey"
Invoke-Expression ((New-Object System.Net.Webclient).DownloadString('https://chocolatey.org/install.ps1'))
CINST Boxstarter -y
CINST chef-client -y

Write-Output "Importing Boxstart Chocolatey and WinConfig Modules"
Import-Module "$env:appdata\boxstarter\boxstarter.chocolatey\boxstarter.chocolatey.psd1"
Import-Module "$env:appdata\boxstarter\boxstarter.WinConfig\boxstarter.WinConfig.psd1"
$CBCResult.Completed = $true
if (Test-PendingReboot) {
    Write-Output "Chocolately, Boxstarter, and Chef Execution completed successfully but a reboot is required."
    $CBCResult.Reboot = $true
}else{
    Write-Output "Chocolately, Boxstarter, and Chef Execution completed successfully."
    $CBCResult.Reboot = $false
}

$CBCResult