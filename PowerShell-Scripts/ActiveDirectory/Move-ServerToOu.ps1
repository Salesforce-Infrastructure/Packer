<#
    .SYNOPSIS
    Move server(s) to a target AD OU.

    .DESCRIPTION
    Give a sinlge or multiple servers in array, Move them to target OU.
    Targer location should be passed as Distinguish Name as a string.
    See example.

    .PARAMETER ComputerName
    Name of computer to be move. If multiple, provide in an array.

    .PARAMETER TargetDN
    Target Distinguish Name in a string.

    .PARAMETER Credential
    Optional Credential - ("QA\Administrator", "Password")

    .EXAMPLE
    scriptName.ps1 ("WIN16SERVER", "WIN12CLIENT") "OU=innerOU,OU,outterOU,OU=SQL,DC=QA,DC=local" 
    
    .EXAMPLE
    scriptName.ps1 ("WIN16SERVER", "WIN12CLIENT") "OU=innerOU,OU=outterOU,OU=SQL,DC=QA,DC=local" ("QA\Administrator", "Password")

    .EXAMPLE
    scriptName.ps1 "WIN16SERVER" "OU=SQL,DC=QA,DC=local"

    .NOTES
    Author Thawngzapum Lian
    Date   05/02/2017
#>

param(
    [Parameter(Position=0, 
               HelpMessage="Computer name. If multiple, comma separated")]
    [ValidateNotNullOrEmpty()]
    $ComputerName,
    [Parameter(Position=1,
               HelpMessage='Target Distinguish Name (DN) as a string.1 `
                            "OU=innerNest,OU=outterNest,OU=SQL,DC=QA,DC=LOCAL"')]
    [ValidateNotNullOrEmpty()]
    [string]$TargetDN,
    [Parameter(Position=2,
               HelpMessage='Optional credential - ("QA\Administrator", "password")')]
    $Credential = @()
)

Function Move-ServerToOu {
    $params = @{ '-TargetPath'=$TargetDN }

    if ($Credential) {
        $PWD = ConvertTo-SecureString -AsPlainText -Force -String $Credential[1]
        $CREDOBJ = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Credential[0], $PWD)
        $params.Add('-Credential', $CREDOBJ)
    }

    $ComputerName | % {
        Try {
            Get-ADComputer $_ | Move-ADObject @params
        }
        Catch {
            $_.Exception.Message
            Continue
        }
        finally {
            Get-ADComputer $_
        }
    }
}

Move-ServerToOu

