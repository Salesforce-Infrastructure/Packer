$OS = Get-WmiObject Win32_OperatingSystem
if($OS.Caption.StartsWith("Microsoft Windows Server 2008 R2")){
    $OutFile = "C:\KB3020369.msu"
    Write-Output "Downloading servicing update KB3020369 to $OutFile"
    (New-Object System.Net.Webclient).DownloadFile("http://download.windowsupdate.com/d/msdownload/update/software/updt/2015/04/windows6.1-kb3020369-x64_5393066469758e619f21731fc31ff2d109595445.msu",$OutFile)

    Write-Output "Attempting to install update KB3020369."
    Start-Process -FilePath "C:\Windows\System32\wusa.exe" -ArgumentList "$OutFile /quiet /norestart" -Wait

    Write-Output "Removing update file $OutFile."
    Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
}else {
    Write-Output "The operating system is not valid for this patch, skipping."
}