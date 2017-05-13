param(
    [Parameter(ParameterSetName="0")]
    [Switch]$Enable,
    [Parameter(ParameterSetName="0")]
    [Switch]$DelayedAuto,
    [Parameter(ParameterSetName="1")]
    [Switch]$Disable,
    [Parameter(ParameterSetName="2")]
    [Switch]$Stop,
    [Parameter(ParameterSetName="3")]
    [Switch]$Start,
    [Switch]$Reboot
)

if($Enable){
    try {
        Write-Output "Enabling and configuring WinRM and PSRemoting."
        Set-Service -Name winrm -StartupType Automatic
        Stop-Service winrm -ErrorAction SilentlyContinue
        Enable-PSRemoting -Force -ErrorAction SilentlyContinue
        Set-WSManQuickConfig -Force -ErrorAction SilentlyContinue
        Enable-WSManCredSSP -Force -Role Server
        winrm set winrm/config/client/auth '@{Basic="true"}'
        winrm set winrm/config/service/auth '@{Basic="true"}'
        winrm set winrm/config/service '@{AllowUnencrypted="true"}'
        winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'
        netsh.exe advfirewall firewall set rule group="Remote Administration" new enable=yes
        netsh.exe advfirewall firewall add rule name="WinRM Port" protocol=TCP dir=in remoteport=5985 action=allow
        if ($DelayedAuto) {
            SC.exe config winrm start= Delayed-Auto
        }
        Start-Service winrm
    }
    catch {
        Write-Output "An error occured:"
        Write-Output $_.Exception.Message
    }
}elseif($Disable)
{
    try {
        Write-Output "Disabling WinRM and PSRemoting."
        $WinRM = Get-Service winrm
        if($WinRM.StartType -ne "Disabled"){
            Write-Output "Disabling PSRemoting and WsManCredSSP"
            Disable-WSManCredSSP -Role Server -ErrorAction SilentlyContinue
            Disable-PSRemoting -Force
            Write-Output "Stopping service and setting to disabled."
            Stop-Service winrm -Force
            Set-Service -Name winrm -StartupType Disabled
            Write-Output "Service settings changed without error."
        }
        Write-Output "Modifying firewall rules."
        netsh.exe advfirewall firewall set rule group="Remote Administration" new enable=no
        netsh.exe advfirewall firewall delete rule name="WinRM Port" protocol=TCP remoteport=5985
    }
    catch {
        Write-Output "An error occured:"
        Write-Output $_.Exception.Message
    }
}elseif ($Stop){
    Write-Output "Stopping WinRM."
    Stop-Service winrm
}elseif($Start){
    Write-Output "Starting WinRM."
    Start-Service winrm
}else{
    Write-Error -Message "Please specify either the -ENABLE -DISABLE or -STOP switch."
}
if ($Reboot) {
    Write-Output "Rebooting."
    Restart-Computer -Force
    Write-Output "Waiting for Reboot..."
    Start-Sleep 30
}

