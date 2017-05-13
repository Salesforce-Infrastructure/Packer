param(
  [string]$user,
  [string]$pass,
  [string]$ip,
  [string]$hostname,
  [Int]$maxCount = 15,
  [Int]$sleepTime = 30
)

$secpasswd = ConvertTo-SecureString -AsPlainText "$pass" -Force
$mycreds = New-Object System.Management.Automation.PSCredential($user, $secpasswd)

$skipCN = New-PSSessionoption -SkipCNCheck -SkipCACheck

Write-Output "Invoking Command"
$configJob = Invoke-Command -computername $ip -UseSSL -SessionOption $skipCN -Credential $mycreds -FilePath $PSScriptRoot\Set-MaasNetworkConfig.ps1 -AsJob

$count = 0
while( -Not( Test-Connection -ComputerName $hostname -BufferSize 16 -Count 1 -Quiet ) ) {
  Write-Output "[$count] $hostname is not up."
  if( $count -lt $maxCount ){
    Write-Output "[$count] Waiting $sleepTime seconds and trying again."
    $count++
    start-sleep -seconds $sleepTime
  } else {
    Write-Output "Max of $maxCount tries reached."
    Write-Output "FAILURE"
    Exit 404
  }
}

Write-Output "$hostname is up and reachable!"
Write-Output "Checking if the job still has more data"

while( $configJob.HasMoreData ) {
  if( $count -lt $maxCount ){
    Write-Output "[$count] Job still has data. Waiting $sleepTime and checking again."
    $count++
    start-sleep -second $sleepTime
  } else {
    Write-Output "Max time taken ($maxCount X $sleepTime). Exiting."
    Write-Output "FAILURE"
    exit 404
  }
}

Write-Output "SUCCESS"
Exit 0
