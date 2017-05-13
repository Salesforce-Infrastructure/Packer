$P51Result = $null
C:\PackerScripts\PO-ResultObject.ps1
$P51Result = Import-Clixml -Path ".\PO-ResultObject.xml"

Write-Output "Downloading Windows Management Framework 5.1"
$OS = Get-WmiObject Win32_OperatingSystem
if ($OS.Caption.StartsWith("Microsoft Windows Server 2012 R2")) {
    $Posh51Path = "C:\Win8.1AndW2K12R2-KB3191564-x64.msu"
    $Posh51Url = "http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu"
    (New-Object System.Net.Webclient).DownloadFile($Posh51Url,$Posh51Path)
    Start-Process -FilePath "C:\Windows\System32\wusa.exe" -ArgumentList "$Posh51Path /quiet /norestart" -Wait
    Write-Output "Removing update file $Posh51Path."
    Remove-Item $Posh51Path -Force -ErrorAction SilentlyContinue
    $P51Result.Reboot = $true
}elseif($OS.Caption.StartsWith("Microsoft Windows Server 2008 R2")){
    $Posh51Path = "C:\Win7AndW2K8R2-KB3191566-x64.zip"
    $Posh51Url = "http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7AndW2K8R2-KB3191566-x64.zip"
    (New-Object System.Net.Webclient).DownloadFile($Posh51Url,$Posh51Path)
    Expand-ZipFile -SourceFile $Posh51Path -Destination "C:\PowerShell51\" -OverwriteExisting
    #[System.IO.Compression.ZipFile]::ExtractToDirectory($Posh51Path,"C:\PowerShell51\")

    Write-Output "Installing Windows Management Framework 5.1"
    C:\PowerShell51\Install-WMF5.1.ps1 -AcceptEULA
    $Reboot = $false
    do {
        $Reg = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\"
        for ($i = 0; $i -lt $Reg.Count; $i++) {
            if($Reg[$i].ToString().Contains("RebootRequired")){
                $Reboot = $true
                break
            }else{
                $Reboot = $false
            }
        }
        if ($Reboot -eq $true) {
            Write-Output "A reboot is now required, WMF 5.1 is considered to be installed successfully."
            break
        }else{
            Write-Output "Waiting for install to complete... pausing for 10 seconds and then checking again..."
            Write-Output "..."
            Start-Sleep -Seconds 10
        }
    } until ($Reboot -eq $true)

    Write-Output "WMF 5.1 installation is complete, rebooting now."
    $P51Result.Reboot = $true
}
$P51Result.Completed = $true
$P51Result

