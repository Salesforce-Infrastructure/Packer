$secpasswd = ConvertTo-SecureString 'vagrant' -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ('vagrant', $secpasswd)
New-PSSession -ComputerName '10.114.8.87' -Credential $Cred -Authentication Basic
Remove-PSSession $Session
