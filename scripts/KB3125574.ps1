$OS = Get-WmiObject Win32_OperatingSystem
if($OS.Caption.StartsWith("Microsoft Windows Server 2008 R2")){
    $OutFile = "C:\KB3125574.msu"
    Write-Output "Downloading convenience update KB3125574 to $OutFile"
    (New-Object System.Net.Webclient).DownloadFile("http://download.windowsupdate.com/d/msdownload/update/software/updt/2016/05/windows6.1-kb3125574-v4-x64_2dafb1d203c8964239af3048b5dd4b1264cd93b9.msu",$OutFile)

    Write-Output "Attempting to install update KB3125574."
    Start-Process -FilePath "C:\Windows\System32\wusa.exe" -ArgumentList "$OutFile /quiet /norestart" -Wait

    Write-Output "Removing update file $OutFile."
    Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
}else {
    Write-Output "The operating system is not valid for this patch, skipping."
}