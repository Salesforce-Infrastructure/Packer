$OS = Get-WmiObject Win32_OperatingSystem
if($OS.Caption.StartsWith("Microsoft Windows Server 2008 R2")){
    Write-Output "Attempting to install sysprep hotfix KB2693187."
    Start-Process -FilePath "C:\Windows\System32\wusa.exe" -ArgumentList "A:\Windows6.1-KB2693187-x64.msu /quiet /norestart" -Wait
    Write-Output "Update install complete, rebooting."
}else{
    Write-Output "The operating system is not valid for this patch, skipping."
}