$dotNetResult = $null
C:\PackerScripts\PO-ResultObject.ps1
$dotNetResult = Import-Clixml -Path ".\PO-ResultObject.xml"

$OS = Get-WmiObject Win32_OperatingSystem
Write-Output "The installed Operating System is $($OS.Caption)."
if ($OS.Caption.StartsWith("Microsoft Windows Server 2016")){
    Write-Output ".Net 4.5.2 is not needed on this OS."
    $dotNetResult.Reboot = $false
    $dotNetResult.Completed = $true
}else{
    $NetFXPath = "C:\NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
    $NetFXUrl = "https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe"

    Write-Output "Attempting to download .Net 4.5.2."
    (New-Object System.Net.Webclient).DownloadFile($NetFXUrl,$NetFXPath)
    Write-Output "Attempting to install .Net 4.5.2."
    Start-Process -FilePath $NetFXPath -ArgumentList "/quiet /norestart" -Wait
    Remove-Item $NetFXPath -Force -ErrorAction SilentlyContinue
    Write-Output ".Net 4.5.2 installation is complete, a reboot will be required."
    $dotNetResult.Reboot = $true
    $dotNetResult.Completed = $true
}
$dotNetResult