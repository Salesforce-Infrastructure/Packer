Write-Output "Disabling Vagrant user autologon."
$WinlogonPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Remove-ItemProperty -Path $WinlogonPath -Name AutoAdminLogon
Remove-ItemProperty -Path $WinlogonPath -Name DefaultUserName

Write-Output "Cleaning up PowerShell install."
Remove-Item "C:\PowerShell51" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "C:\Win7AndW2K8R2-KB3191566-x64.zip" -Force -ErrorAction SilentlyContinue

Write-Output "Deleting temporary files and folders."
Remove-Item "$env:TEMP\*" -Recurse -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -ErrorAction SilentlyContinue

Write-Output "Removing Packer Scripts Directory."
Remove-Item "C:\PackerScripts" -Recurse -ErrorAction SilentlyContinue
Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\PackerOrchestratorStart.bat" -Force -ErrorAction SilentlyContinue

Write-Output "Deleting Pagefile"
$pageFileMemoryKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $pageFileMemoryKey -Name PagingFiles -Value ""

<#
Write-Output "Cleaning WinSXS, running multiple times because it usually fails the first."
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
#>

Write-Output "Defragmenting the C drive."
$cDisk = Get-WMIObject -Class Win32_Volume -Filter "DriveLetter = 'c:'"
$cDisk.Defrag($true)

Write-Output "Cleaning free space."
Invoke-WebRequest https://download.sysinternals.com/files/SDelete.zip -OutFile "C:\sdelete.zip"
Add-Type -Assembly System.IO.Compression.Filesystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("C:\sdelete.zip","C:\Windows\System32\")
Remove-Item "C:\sdelete.zip" -Force -ErrorAction SilentlyContinue
./sdelete.exe /accepteula -z c:
Remove-Item "C:\Windows\System32\sdelete.exe" -Force -ErrorAction SilentlyContinue
Write-Output "Finished cleaning free space."

Write-Output "Re-enabling Pagefile on next boot"
$System = GWMI Win32_ComputerSystem -EnableAllPrivileges
$System.AutomaticManagedPagefile = $true
$System.Put()

Write-Output "All cleanup tasks have completed."