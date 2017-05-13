function Export-POResultObject{
    $obj = New-Object PSCustomObject
    $obj | Add-Member -MemberType NoteProperty -Name Completed -Value $null
    $obj | Add-Member -MemberType NoteProperty -Name Reboot -Value $null
    Export-Clixml -Path ".\PO-ResultObject.xml" -InputObject $obj -Force
}
Export-POResultObject

