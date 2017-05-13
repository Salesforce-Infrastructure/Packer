$cInitResult = $null
C:\PackerScripts\PO-ResultObject.ps1
$cInitResult = Import-Clixml -Path ".\PO-ResultObject.xml"
if (Test-Path "A:\Physical.pac") {
    $cInitPath = "C:\CloudbaseInitSetup_0_9_11_x64.msi"
    $cInitUrl = "https://cloudbase.it/downloads/CloudbaseInitSetup_0_9_11_x64.msi"
    (New-Object System.Net.Webclient).DownloadFile($cInitUrl,$cInitPath)
    Start-Process -FilePath C:\Windows\System32\msiexec.exe -ArgumentList "/i $cInitPath /qb /norestart" -Wait
    SC.exe config cloudbase-init start= Disabled
    Write-Output "Removing update file $cInitPath."
    Remove-Item $cInitPath -Force -ErrorAction SilentlyContinue
    Copy-Item "C:\PackerScripts\cloudinit-config\Set-MaasNetworkConfig.ps1" -Destination "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts"
    Add-Content -Path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf" -Value "plugins=cloudbaseinit.plugins.common.mtu.MTUPlugin,cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin,cloudbaseinit.plugins.windows.ntpclient.NTPClientPlugin,cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin,cloudbaseinit.plugins.common.userdata.UserDataPlugin,cloudbaseinit.plugins.windows.winrmlistener.ConfigWinRMListenerPlugin,cloudbaseinit.plugins.windows.winrmcertificateauth.ConfigWinRMCertificateAuthPlugin,cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin"
    if ((Get-WmiObject Win32_Product | where {$_.Name.StartsWith("Cloudbase-Init")}) -eq $null) {
        $cInitResult.Completed = $false
        $cInitResult.Reboot = $true
    }else{
        $cInitResult.Completed = $true
        if((Test-PendingReboot).RebootPending -eq $true){
            $cInitResult.Reboot = $true
        }else{
            $cInitResult.Reboot = $false
        }
    }
}else{
    $cInitResult.Completed = $true
    $cInitResult.Reboot = $false
}
$cInitResult
