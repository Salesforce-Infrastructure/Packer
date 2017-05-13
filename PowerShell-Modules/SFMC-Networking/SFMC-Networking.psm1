####################################################################################################
#   MODULE NAME :   SFMC-NETWORKING
#   USAGE       :   Allows for simplified scripting of SFMC-specific network configuration activities
#   AUTHOR      :   Ben Lutterbach
#   PLATFORM    :   Windows Server 2016 (Tested), 2012/2012 R2 (Untested), 2008 R2 (Untested, likely won't work)
#   REQUIRES    :   PowerShell 3.0 or higher (Tested on PowerShell 5.1)
####################################################################################################

<#
.SYNOPSIS

Sets the Trasmit and/or Receive buffers of a specified network adapter.
.DESCRIPTION

Sets the Trasmit and/or Receive buffers of a specified network adapter.
.PARAMETER AdapterName

The name of the adapter you would like to modify.
.PARAMETER BufferSize

The size (as a number) that you would like to set the buffer values too.  Please ensure that you are setting a value that is supported by your hardware vendor.
.PARAMETER BufferType

Supported values:  Receive, Trasmit, Both
Default value is BOTH
    Receive - will only set the Receive Buffers
    Trasmit - will only set the Trasmit Buffers
    Both - will set both Buffers to the specified value
.EXAMPLE

Set-McNicBuffers -AdapterName "Ethernet" -BufferSize 4096 -BufferType Transmit
Set the Transmit Buffer on 'Ethernet' to 4096
.EXAMPLE

Set-McNicBuffers -AdapterName "Ethernet" -BufferSize 2048
Set both the Transmit and Receive Buffers on 'Ethernet' to 2048
#>
function Set-McNicBuffers (
    [Parameter(Mandatory=$true)]
    [string]$AdapterName,
    [Parameter(Mandatory=$true)]
    [int]$BufferSize,
    [Parameter(Mandatory=$false)][ValidateSet("Receive","Transmit","Both")]
    [string]$BufferType="Both"
) {
    try{
        Write-Host "Setting buffer information on $AdapterName." -ForegroundColor Yellow
        if ($BufferType -eq "Receive") {
            Write-Host "Setting Receive Buffer value to $BufferSize."
            Set-NetAdapterAdvancedProperty -Name $AdapterName -DisplayName "Receive Buffers" -DisplayValue $BufferSize 
        }elseif ($BufferType -eq "Transmit") {
            Write-Host "Setting Transmit Buffer value to $BufferSize."
            Set-NetAdapterAdvancedProperty -Name $AdapterName -DisplayName "Transmit Buffers" -DisplayValue $BufferSize
        }else{
            Write-Host "Setting Receive Buffer value to $BufferSize."
            Set-NetAdapterAdvancedProperty -Name $AdapterName -DisplayName "Receive Buffers" -DisplayValue $BufferSize
            Write-Host "Setting Transmit Buffer value to $BufferSize."
            Set-NetAdapterAdvancedProperty -Name $AdapterName -DisplayName "Transmit Buffers" -DisplayValue $BufferSize
        }
        Write-Host "Process completed without error!" -ForegroundColor Green
    }catch{
        Write-Error $_
    }
}

<#
.SYNOPSIS

Sets static IP information on a network adapter or team.
.DESCRIPTION

Sets static IP information on a network adapter or team.
.PARAMETER AdapterName

The name of the adapter you would like to set IP information for.
.PARAMETER IpAddress

The IP address to set.
.PARAMETER SubnetSize

The subnet size to use.
    Accepted values are in between 16 and 30.

.PARAMETER DefaultGateway

The default gateway to set on the adapter, in required.

.PARAMETER PrimaryDNS

Sets the Primary DNS value.

.PARAMETER SecondaryDNS

Sets the Secondary DNS value (must define a Primary DNS in order for this to work right).

.PARAMETER DnsServers

In place of setting Primary and Secondary DNS values, you may simply specify an Object[] of DNS servers.
.EXAMPLE

Set-McStaticIP -AdapterName "Ethernet" -IpAddress "192.168.1.100" -SubnetSize 24 -DefaultGateway "192.168.1.1" -PrimaryDNS "8.8.8.8" -SecondaryDNS "8.8.4.4"
.EXAMPLE

$Dns = @()
$Dns += "8.8.4.4"
$Dns += "8.8.8.8"
Set-McStaticIP -AdapterName "Ethernet" -IpAddress "192.168.1.100" -SubnetSize 22 -DefaultGateway "192.168.1.1" -DnsServers $Dns
#>
function Set-McStaticIP (
    [Parameter(Mandatory=$true)]
    [string]$AdapterName,
    [Parameter(Mandatory=$true)]
    [string]$IpAddress,
    [Parameter(Mandatory=$true)][ValidateRange(16,30)]
    [int]$SubnetSize,
    [Parameter(Mandatory=$false)]
    [string]$DefaultGateway,
    [Parameter(Mandatory=$false,ParameterSetName=0)]
    [string]$PrimaryDNS,
    [Parameter(Mandatory=$false,ParameterSetName=0)]
    [string]$SecondaryDNS,
    [Parameter(Mandatory=$false,ParameterSetName=1)]
    [Object[]]$DnsServers
) {
    try {
        # Reset Adapter and Gather Base Information
        Write-Host "Reseting adapter before writing new information." -ForegroundColor Yellow
        Reset-McNetAdapter -AdapterName $AdapterName -DhcpStatus Disabled
        $IPConf = Get-NetAdapter -Name $AdapterName | Get-NetIPConfiguration | Select *

        # First, remove any lingering default gateway settings, if they exist which can persist even in DHCP mode (though it is not used).
        # Not doing so can cause errors.
        if($IPConf.IPv4DefaultGateway -ne $null){
            $IPConf | Remove-NetRoute -NextHop $IPConf.IPv4DefaultGateway.NextHop -Confirm:$false
        }

        # Set IP Info
        Write-Host "Setting IP values." -ForegroundColor Yellow
        $DefaultGateway = $DefaultGateway
        if($DefaultGateway.Length -eq 0){
            $IPConf | New-NetIPAddress -IPAddress $IpAddress -PrefixLength $SubnetSize
        }else{
            $IPConf | New-NetIPAddress -IPAddress $IpAddress -PrefixLength $SubnetSize -DefaultGateway $DefaultGateway
        }

        # Verify DNS info and set if not null
        if ($DnsServers -eq $null) {
            $PrimaryDNS = $PrimaryDNS
            $SecondaryDNS = $SecondaryDNS
            if($PrimaryDNS -ne $null){
                $DnsServers = $PrimaryDNS
                if($SecondaryDNS -ne $null){
                    $DnsServers = ("$DnsServers,$SecondaryDNS").TrimStart(',').TrimEnd(',')
                }
            }     
        }
        if($DnsServers -ne $null){
            Write-Host "Setting DNS server values." -ForegroundColor Yellow
            $IPConf | Set-DnsClientServerAddress -ServerAddresses $DnsServers
        }
        Write-Host "IP information set successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error $_
    }
}

<#
.SYNOPSIS

Resets a network adapter to default values (DHCP enabled) OR removes all configuration settings.
.DESCRIPTION

Resets a network adapter to default values (DHCP enabled) OR removes all configuration settings.
.PARAMETER AdapterName

The name of the adapter you would like to reset IP information for.
.PARAMETER DhcpStatus

Supported values:  Enabled, Disabled
Default value is ENABLED
    Enabled - enables DHCP
    Disabled - disables DHCP, which will leave the adapter without any IP information.  Note that this may disrupt network connection if no other active adapters are present.
.EXAMPLE

Reset-McNetAdapter -AdapterName "Ethernet" -DhcpStatus Disabled
Blanks the adapter's IP information.
.EXAMPLE

Reset-McNetAdapter -AdapterName "Ethernet"
Resets the adapters information and enables DHCP.
#>
function Reset-McNetAdapter (
    [Parameter(Mandatory=$true)]
    [string]$AdapterName,
    [Parameter(Mandatory=$false)][ValidateSet("Enabled","Disabled")]
    [string]$DhcpStatus="Enabled"
) {
    try {
        $IPConf = Get-NetAdapter -Name $AdapterName | Get-NetIPConfiguration | Select *
        $DHCP = $IPConf | Get-NetIPInterface | where {$_.AddressFamily -eq "IPv4" -and $_.DHCP -eq "Enabled"}
        Write-Host "Reseting network adapter." -ForegroundColor Yellow
        if($DHCP -eq $null) {
            $IPConf | Remove-NetIPAddress -Confirm:$false
            $IPConf | Set-DnsClientServerAddress -ResetServerAddresses
        }else {
            # If DHCP then we're going to disable that first.
            foreach ($entry in $DHCP) {
                if ($DhcpStatus -eq "Enabled") {
                    Set-NetIPInterface -InputObject $entry -Dhcp Enabled
                }else{
                    Set-NetIPInterface -InputObject $entry -Dhcp Disabled
                }
            }
        }
        Write-Host "Process completed without error!" -ForegroundColor Green
    }
    catch {
        Write-Error $_
    }
}

<#
.SYNOPSIS

Sets the name of a network adapter.
.DESCRIPTION

Sets the name of a network adapter.
.PARAMETER NewName

The new name of the network adapter
.PARAMETER Bus

The PCI Bus ID, cannot be used with -OldName.
.PARAMETER Device

The PCI Device ID, cannot be used with -OldName.
.PARAMETER Function

The PCI Function ID, cannot be used with -OldName.
.PARAMETER OldName

Rename the adapter by searching for the currently existing name, cannot be used with -Bus, -Device, and -Function
.EXAMPLE

Set-McNicName -NewName "SkyNic" -OldName "Ethernet"
.EXAMPLE

Set-McNicName -NewName "SkyNic" -Bus 7 -Device 4 -Function 0
Sets the name of the nic based on the "General" tab of the network adapters properties page from Device Manager.
#>
function Set-McNicName (
    [Parameter(Mandatory=$true)]
    [string]$NewName,
    [Parameter(Mandatory=$true,ParameterSetName=0)]
    [int]$Bus,
    [Parameter(Mandatory=$true,ParameterSetName=0)]
    [int]$Device,
    [Parameter(Mandatory=$true,ParameterSetName=0)]
    [int]$Function,
    [Parameter(Mandatory=$true,ParameterSetName=1)]
    [string]$OldName
) {
    try{
        if ($OldName -eq $null) {
            Get-NetAdapterHardwareInfo | ForEach-Object {
                if ($_.Bus -eq $Bus -and $_.Device -eq $Device -and $_.Function -eq $Function){
                    Write-Host "Matching adapter found, renaming." -ForegroundColor Yellow
                    Rename-NetAdapter -Name $_.Name -NewName $NewName
                    Write-Host "Process complete without error!" -ForegroundColor Green
                }
            }
        }else{
            Rename-NetAdapter -Name $OldName -NewName $NewName 
        }
        
    }catch{
        Write-Error $_
    }
}

<#
.SYNOPSIS

Creates a Team from the specified network adapters.  In addition a team may be renamed as long as all the correct team members are specified with a different name, and members may be added as long the correct existing team name is specified.
.DESCRIPTION

Creates a Team from the specified network adapters.
.PARAMETER TeamName

The name of the new team.
.PARAMETER TeamMembers

An object array (Object[]) of the members of the team.
.PARAMETER Mode

Supported values:  Static, SwitchIndependent, Lacp
Sets the Team Mode to be utilized.  See your hardware documentation for supported Teaming Modes
.EXAMPLE

$Members = @()
$Members += "Eth01"
$Members += "Eth02"
$Members += "Eth03"
$Members += "Eth04"
Set-McNicTeam -TeamName "Uber-Team" -TeamMembers $Members -Mode Lacp
.EXAMPLE

Set-McNicTeam -TeamName "Uber-Team" -TeamMembers Ethernet,Ethernet01,Ethernet02 -Mode Static
.EXAMPLE

Set-McNicTeam -TeamName "New-Uber-Team" -TeamMembers Ethernet,Ethernet01,Ethernet02 -Mode Static
Effective renames the the team set in the previous example.

.EXAMPLE

Set-McNicTeam -TeamName "New-Uber-Team" -TeamMembers Ethernet03 -Mode Static
Adds Ethernet03 to the team set in th previous example.
#>
function Set-McNicTeam (
    [Parameter(Mandatory=$true)]
    [string]$TeamName,
    [Parameter(Mandatory=$true)]
    [Object[]]$TeamMembers,
    [Parameter(Mandatory=$true)][ValidateSet("Static","SwitchIndependent","Lacp")]
    $Mode
) {
    try{
        if ((Get-NetLbfoTeam -Name $TeamName -ErrorAction SilentlyContinue) -eq $null) {
            $Team = Get-NetLbfoTeamMember -Name $TeamMembers -ErrorAction SilentlyContinue
            if($Team -ne $null) {
                Write-Host "Each specified TeamMember is a member of an existing Team with a different name, renaming existing Team to match the TeamName parameter." -ForegroundColor Yellow
                Rename-NetLbfoTeam -Name $Team.Team[0] -NewName $TeamName
            }else{
                Write-Host "Creating new Team." -ForegroundColor Yellow
                New-NetLbfoTeam -Name $TeamName -TeamMembers $TeamMembers -TeamingMode $Mode -confirm:$false
            }
        }else{
            if ($TeamMembers -ne $null) {
                foreach ($nic in $TeamMembers) {
                    if((Get-NetLbfoTeam -Name $TeamName).Members -notcontains $nic){
                        Write-Host "Adding $nic to existing team $TeamName." -ForegroundColor Yellow
                        Add-NetLbfoTeamMember -Name $nic -Team $TeamName -Confirm:$false
                    }else{
                        Write-Error "An error may have occured in how you entered your TeamName or TeamMembers as no action is able to be taken.  Please check your inputs and try again."
                    }
                }
            }
        }
        Write-Host "Processing has completed, checking for the Team to be in an 'UP' state." -ForegroundColor Yellow
        $CheckCount = 0
        do {
            $Complete = $false
            if ((Get-NetLbfoTeam -Name $TeamName).Status -eq "Up") {
                Write-Host "The team was created and brought online successfully!" -ForegroundColor Green
                $Complete = $true
            }else{
                $Complete = $false
                $CheckCount++
                if ($CheckCount -gt 24) {
                    Write-Error "The NIC teams are not up after 4 minutes, stopping the check."
                }else{
                    Write-Warning "The team is still not Up, waiting 10 seconds and rechecking."
                    Start-Sleep -Seconds 10
                }
            }
        } until ($Complete)
    }catch{
        Write-Error $_
    }
}

<#
.SYNOPSIS

Tags a VLan on a designated network team.
.DESCRIPTION

Tags a VLan on a designated network team.
.PARAMETER TeamName

The name of the team to tag the vlan on.
.PARAMETER VlanID

The VLan to tag on the team.
.PARAMETER Reset

Removes currently tagged VLan.
.EXAMPLE

Set-McTeamVlan -TeamName "Uber-Team" -VlanID 188
.EXAMPLE

Set-McTeamVlan -TeamName "Uber-Team" -Reset
#>
function Set-McTeamVlan (
    [Parameter(Mandatory=$true)]
    [string]$TeamName,
    [Parameter(Mandatory=$false,ParameterSetName=0)]
    [int]$VlanID,
    [Parameter(Mandatory=$true,ParameterSetName=1)]
    [switch]$Reset
) {
    try{
        if ($Reset) {
            Set-NetLbfoTeamNic -Team $TeamName -Default
        }else{
            Set-NetLbfoTeamNic -Team $TeamName -VlanID $VlanID
        }
        Write-Host "Checking to ensure the team return to an 'Up' state before exiting." -ForegroundColor Yellow
        $CheckCount = 0
        do {
            $Complete = $false
            if ((Get-NetLbfoTeam -Name $TeamName).Status -eq "Up") {
                $Complete = $true
                Write-Host "VLan was tagged successfully!" -ForegroundColor Green
            }else{
                $Complete = $false
                $CheckCount++
                if ($CheckCount -gt 24) {
                    Write-Error "The NIC teams are not up after 4 minutes, stopping the check."
                }else{
                    Write-Warning "The team is still not Up, waiting 10 seconds and rechecking."
                    Start-Sleep -Seconds 10
                }
            }
        } until ($Complete)
    }catch{
        Write-Error $_
    }
}