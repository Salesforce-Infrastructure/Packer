#ps1_sysnative
if ((Test-Path "C:/network.json") -eq $false) {
    exit
}

$json = Get-Content -Raw "C:/network.json" | ConvertFrom-Json
$physical = $json.config | where {$_.Type -eq "Physical"}
$team = $json.config | where {$_.Type -eq "Bond"}
$vlan = $json.config | where {$_.Type -eq "vlan"}

Write-Output "Disabling Unused LOM Interfaces..."
Disable-NetAdapter "Embedded LOM*" -Confirm:$false
Write-Output "LOM NICs disabled"

# Associate IDs with NetAdapters
$nicHash = @{}
Foreach ($nic in $physical) {
    $nicHash[$nic.id] = Get-NetAdapter | ? InterfaceDescription -NotLike "*Multiplexor*" | ? MacAddress -eq $nic.mac_address.Replace(':','-').ToUpper()
}
$x = 0
foreach ($t in $team){
    $x++
    Set-McNicTeam -TeamMembers $nicHash[$t.bond_interfaces].Name -TeamName $t.name -Mode SwitchIndependent
    $num = 1
    $TeamIPInfo, $VlanIpInfo, $address, $IP, $Mask, $Gateway, $DnsServers, $n = $null
    foreach ($nic in $t.bond_interfaces){
        Write-Host $nic -ForegroundColor Yellow
        if ($t.name -match "Prod") {
            $n = "P"
        }elseif($t.name -match "HB"){
            $n = "HB"
        }
        Write-Host "Setting Nic name to $n$num"
        Set-McNicName -OldName $nicHash[$nic].Name -NewName $n$num
        Set-McNicBuffers -AdapterName $n$num -BufferType Both -BufferSize 4096
        $num++
    }
    Write-Host "Setting IP information."
    #$TeamIpInfo = $t.subnets
    $VlanIpInfo = ($vlan | where {$_.vlan_link -eq $t.name}).subnets
    if ($VlanIpInfo.item(0) -ne $null) {
        $address = $VlanIpInfo.item(0).address.Split('/')
        $IP = $address[0]
        $Mask = $address[1]
        $Gateway = $IP.Remove($IP.LastIndexOf('.')) + ".254"
        $DnsServers = $VlanIpInfo.dns_nameservers
        Set-McStaticIP -AdapterName $t.name -IpAddress $IP -SubnetSize $Mask -DefaultGateway $Gateway -DnsServers $DnsServers
    }
    Set-McTeamVlan -TeamName $t.name -VlanID ($vlan | where {$_.vlan_link -eq $t.name}).vlan_id
    Set-McNicName -OldName "$($t.name)*" -NewName $t.name
    
    # Add Native VLAN
    Add-NetLbfoTeamNic -Team $t.name -VlanID 0 -Name "Build-$x" -Confirm:$false
}
#cloudbaseinit.plugins.common.mtu.MTUPlugin,cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin,cloudbaseinit.plugins.windows.ntpclient.NTPClientPlugin,cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin,cloudbaseinit.plugins.common.userdata.UserDataPlugin,cloudbaseinit.plugins.windows.winrmlistener.ConfigWinRMListenerPlugin,cloudbaseinit.plugins.windows.winrmcertificateauth.ConfigWinRMCertificateAuthPlugin,cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin