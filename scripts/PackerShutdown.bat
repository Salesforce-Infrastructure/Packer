Echo "mwrock winrm fix"
mkdir -Path $env:windir/setup/scripts/
netsh advfirewall firewall set rule name="WinRM-HTTP" new action=allow
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-in)" new action=allow

Echo "Disabling Administrator account"
net user administrator /active:no

Echo "Enabling Cloud-init Service"
if exist "A:\Physical.pac" (
    sc config cloudbase-init start= Auto
)

Echo "Creating Stamp File"
Echo %Date% %Time% > C:\Windows\System32\Packer

Echo "Running sysprep"
C:/windows/system32/sysprep/sysprep.exe /generalize /oobe /unattend:C:/Windows/Panther/PackerUnattend/Postunattend.xml /quiet /shutdown
