#ps1_sysnative
param(
  [string]$user,
  [string]$pass,
  [string]$domain,
  [string[]]$dnsServers=$null
)
$secpasswd = ConvertTo-SecureString -AsPlainText "$pass" -Force
$mycreds = New-Object System.Management.Automation.PSCredential("$user", $secpasswd)

$prodIndex = Get-Netadapter -Name Prod | Select-Object -ExpandProperty ifIndex
$oldServers = Get-DnsClientServerAddress -InterfaceIndex $prodIndex | Select-Object -ExpandProperty ServerAddresses

if ($dnsServers -ne $null){
  Write-Output "Old DNS Servers: $oldServers"
  Write-Output "Setting DNS Servers to $dnsServers"
  Set-DnsClientServerAddress -InterfaceIndex $prodIndex -ServerAddresses $dnsServers
}

Write-Output "Joining domain $domain"
Add-Computer -DomainName $domain -Credential $myCreds -Force

if ($dnsServers -ne $null){
  Write-Output "Setting DNS back to original servers"
  Set-DnsClientServerAddress -InterfaceIndex $prodIndex -ServerAddresses $oldServers
}

Write-Output "Restarting for domain join to take effect"
Restart-Computer
