$IUResult = $null
C:\PackerScripts\PO-ResultObject.ps1
$IUResult = Import-Clixml -Path ".\PO-ResultObject.xml"

function Test-Completion {
    $OutputDir = "C:\PackerScripts\Install-Updates"
    if ((Test-Path -Path $OutputDir) -eq $false) {
        New-Item -Path $OutputDir -ItemType Directory
    }
    if((Test-PendingReboot).RebootPending -eq $true){
        Write-Output "A reboot is required, rebooting now."
        Remove-Item -Path "$OutputDir\1.reboot" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$OutputDir\2.reboot" -Force -ErrorAction SilentlyContinue
        $IUResult.Reboot = $true
        $IUResult.Completed = $false
    }else{
        if ((Test-Path -Path "$OutputDir\1.reboot") -eq $true) {
            Write-Output "A reboot is not required.  Updates will be checked for 1 additional time before the update processes ends.  If a reboot is required, this counter will reset."
            Rename-Item -Path "$OutputDir\1.reboot" -NewName "2.reboot" -Force
            $IUResult.Reboot = $false
            $IUResult.Completed = $false
        }elseif((Test-Path -Path "$OutputDir\2.reboot") -eq $true){
            Write-Output "All patches appear to be complete."
            Remove-Item -Path "$OutputDir\2.reboot" -Force -ErrorAction SilentlyContinue
            $IUResult.Reboot = $false
            $IUResult.Completed = $true
        }else{
            Write-Output "A reboot is not required.  Updates will be checked for 2 additional time before the update processes ends.  If a reboot is required, this counter will reset."
            New-Item -Path $OutputDir -Name "1.reboot" -ItemType "File"
            $IUResult.Reboot = $false
            $IUResult.Completed = $false
        }
    }
}

#Write-Output "Importing WinUpdate Module"
#Import-Module "$env:appdata\boxstarter\boxstarter.chocolatey\boxstarter.chocolatey.psd1"
#Import-Module "$env:appdata\boxstarter\boxstarter.WinConfig\boxstarter.WinConfig.psd1"
Write-Output "Checking for a required reboot before proceeding."
Test-Completion
if ($IUResult.Reboot) {
    $IUResult
    exit
}

Write-Output "Attempting to install any updates that are found."
Install-WindowsUpdate -AcceptEula
Write-Output "Finished installing updates."
Write-Output "Checking for required reboot."
Test-Completion
if ($IUResult.Reboot) {
    $IUResult
    exit
}

Write-Output "Attempting to install any additional updates."
Install-WindowsUpdate -AcceptEula
Write-Output "Finished installing updates."
Write-Output "Checking for required reboot."
Test-Completion
if ($IUResult.Reboot) {
    $IUResult
    exit
}

Write-Output "Attempting to install any final updates."
Install-WindowsUpdate -AcceptEula
Write-Output "Finished installing updates."
Write-Output "Checking for required reboot."
Test-Completion
if ($IUResult.Reboot) {
    $IUResult
    exit
}

Write-Output "All update installation tasks complete."
$IUResult