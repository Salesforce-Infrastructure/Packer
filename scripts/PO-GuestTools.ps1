$ToolsResult = $null
C:\PackerScripts\PO-ResultObject.ps1
$ToolsResult = Import-Clixml -Path ".\PO-ResultObject.xml"

# VMware Tools
if ((Test-Path "A:\Physical.pac") -eq $false) {
  if (Test-Path "c:/users/vagrant/windows.iso") {
    Write-Output "Installing VMware Tools"
    Mount-DiskImage "C:\Users\vagrant\windows.iso"
    Start-Process -FilePath "E:\setup64.exe" -ArgumentList "/S /v /qn REBOOT=R" -Wait
  }

  #Virtualbox Tools
  if(Test-Path "e:/VBoxWindowsAdditions.exe") {
    Write-Output "Importing Oracle certs and installing Virtualbox Guest Additions."
    certutil -addstore -f "TrustedPublisher" E:\cert\vbox-sha1.cer
    certutil -addstore -f "TrustedPublisher" E:\cert\vbox-sha256.cer
    certutil -addstore -f "TrustedPublisher" E:\cert\vbox-sha256-r3.cer
    Start-Process -FilePath "E:\VBoxWindowsAdditions.exe" -ArgumentList "/S" -Wait
  }
  $ToolsResult.Completed = $true
  $ToolsResult.Reboot = $true
}else {
  $ToolsResult.Completed = $true
  $ToolsResult.Reboot = $false
}
$ToolsResult
