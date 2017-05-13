#ps1_sysnative
<#
    .SYNOPSIS
    Join a computer to a given domain

    .DESCRIPTION
    Connects to a remote computer and joins it to a given domain.

    .PARAMETER RemoteUser
    Username to use when connecting to the remote computer

    .PARAMETER RemotePassword
    Password to use when connecting to the remote computer

    .PARAMETER TargetServer
    IP or Hostname of the computer that needs to join the domain

    .PARAMETER Domain
    Name of the Domain to join (e.g. "qa.local")

    .PARAMETER DomainUser
    Username for a user that has permission to join computers to the domain.

    .PARAMETER DomainPassword
    Password for the domain user .

    .PARAMETER Restart
    If this is set, the computer will restart after joining the domain. Otherwise,
    a manual restart will be needed later for the changes to take effect.

    .EXAMPLE
    scriptName.ps1 10.0.0.1 qa.local vagrant "VerySecret" "qa\uberuser" "SuperSecret"

    .EXAMPLE
    scriptName.ps1 -TargetServer 10.0.0.1 -Domain qa.local -RemoteUser vagrant -RemotePassword "VerySecret" -DomainUser "qa\uberuser" -DomainPassword "SuperSecret" -Restart

    .NOTES
    Author Robert Van Kleeck
    Date   05/09/2017
#>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,
    Position=0,
    HelpMessage="IP or Hostname of the computer to join")]
  [string]$TargetServer,

  [Parameter(Mandatory=$True,
    Position=1,
    HelpMessage="Domain name to join")]
    [ValidateSet("qa.local", "xt.local")]
  [string]$Domain,

  [Parameter(Mandatory=$True,
    Position=2,
    HelpMessage="Username to use when connecting to the remote computer")]
  [string]$RemoteUser,

  [Parameter(Mandatory=$True,
    Position=3,
    HelpMessage="Password to use when connecting to the remote computer")]
  [string]$RemotePassword,

  [Parameter(Mandatory=$True,
    Position=4,
    HelpMessage="Domain user with permission to join to domain.")]
  [string]$DomainUser,

  [Parameter(Mandatory=$True,
    Position=5,
    HelpMessage="Password for the domain user with permission to join to domain.")]
  [string]$DomainPassword,

  [Parameter(Mandatory=$False,
    HelpMessage="Restart computer after domain join")]
  [bool]$Restart
)
$ErrorActionPreference = "Stop"
$RemSecPasswd = ConvertTo-SecureString -AsPlainText "$RemotePassword" -Force
$RemCreds = New-Object System.Management.Automation.PSCredential("$RemoteUser", $RemSecPasswd)
$SkipCN = New-PSSessionoption -SkipCNCheck -SkipCACheck
$DomSecPasswd = ConvertTo-SecureString -AsPlainText "$DomainPassword" -Force
$DomCreds = New-Object System.Management.Automation.PSCredential("$Domain\$($DomainUser.Substring($DomainUser.IndexOf('\') + 1))", $DomSecPasswd)


Write-Verbose "Joining $TargetServer to $Domain"
Try {
    Add-Computer -ComputerName $TargetServer -Domain $Domain -LocalCredential $RemCreds -Credential $DomCreds -Restart:$Restart
    Write-Output "SUCCESS"
    exit 0
} Catch {
    Write-Output "Failed adding $TargetServer to $Domain"
    $_.Exception.ItemName
    $_.Exception.Message
    exit 400
}
