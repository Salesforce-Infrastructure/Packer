netsh advfirewall firewall set rule name="WinRM-HTTP" new action=allow
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-in)" new action=allow
powershell -Command "Enable-PSRemoting -Force"
