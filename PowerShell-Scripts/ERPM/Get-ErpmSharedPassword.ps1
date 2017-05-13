<#
 
NAME: Get-ErpmSharedPassword.ps1
 
AUTHOR:  Ben Lutterbach
DATE  : 5/05/2017
 
PURPOSE: This scrips allows for the retreival of a Shared Password out of ERPM.
 
INPUT:  
    AccountName = Name of account you are retrieving
    SystemName = The System or Computer name field from ERPM, this is required even though the account is a domain account
    PasswordList = The Shared List to get search for the account in
    Environment = QA or XT
    Credential = The PowerShell credential object that has the permissions to retreive the password
    Comment (Optional) = The comment to use for the ERPM Checkout
				                                                                                           
REQUIRED UTILITIES: None

EXAMPLE: PS C:\>$Result = . .\Get-ErpmSharedPassword.ps1 -AccountName "qa\JenkinsSvc-A" -SystemName "Jenkins Service Account - A" -PasswordList "Infrastructure Automation Accounts" -Environment QA -Comment "Because I Need Things!" -ReturnType PSCredential

CHANGE HISTORY:
    Version				DATE			Initials	   	Description of Change
	v1.0				5/05/2017		BL				New Script
#>

param(
    # Script-Level Params
    [Parameter(Mandatory=$false)]
    [ValidateSet("PSCredential","PlainText")]
        [string]$ReturnType,

    # Params That Double for the Get-ErpmSharedPassword Function
    [Parameter(Mandatory=$true)]
        [string]$AccountName,
    [Parameter(Mandatory=$true)]
        [string]$SystemName,
    [Parameter(Mandatory=$true)]
        [string]$PasswordList,
    [Parameter(Mandatory=$true)]
    [ValidateSet("QA","XT")]
        [string]$Environment,
    [Parameter(Mandatory=$true)]
        [PSCredential]$Credential,
    [Parameter(Mandatory=$false)]
        [string]$Comment="Get-ErpmSharedPassword Automated Checkout"
)

function Get-ErpmSharedPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
            [string]$AccountName,
        [Parameter(Mandatory=$true)]
            [string]$SystemName,
        [Parameter(Mandatory=$true)]
            [string]$PasswordList,
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA","XT")]
            [string]$Environment,
        [Parameter(Mandatory=$true)]
            [PSCredential]$Credential,
        [Parameter(Mandatory=$false)]
            [string]$Comment="Get-ErpmSharedPassword Automated Checkout"
    )

    # Get ERPM Server
    switch ($Environment) {
        "QA"{
            $Server = "erpm.qa.local"
        }
        "XT"{
            $Server = "erpm.xt.local"
        }
        default {
            $Server = $null
        }
    }

    if ($Server -eq $null) {
        # Fail and semi-insult the user.
        Write-Error "Somehow the value for the Server is null which is odd considering it's build off of a MANDATORY parameter.  Script might be broken, please consult with the SFMC-InfraAutomation team for assistance."
    }else{
        # Static Variables
        $uri = "https://$Server/ERPMWebService/json/V2/AuthService.svc/"
        $login = "$uri`DoLogin2"
        $logout = "$uri`DoLogout"
        $checkin = "$uri`AccountStoreOps_SharedCredential_CheckOut"
        $checkout = "$uri`AccountStoreOps_SharedCredential_CheckIn"

        # Body Variable Used for REST Authentication
        $body = @{
            "Authenticator" = $Environment
            "LoginType" = "2"
            "Username" = $Credential.UserName
            "Password" = $Credential.GetNetworkCredential().Password
        }
        $json = $body | convertto-json

        # Login to ERPM REST Api and Get Session Token
        $session = Invoke-RestMethod -Method Post -Body $json -Uri $login -ContentType application/json
        $token = $session.OperationMessage
        
        # Body Variable Used for Checking in and Checking Out Password
        $body = @{
            "AuthenticationToken"="$token"
            "Comment"="$Comment"
            "SharedCredentialIdentifier"=@{
                "AccountName"="$AccountName"
                "SharedCredentialListName"="$PasswordList"
                "SystemName"="$SystemName"
            }
        }
        $json = $body | convertto-json
        # Checkin Password, Store As Variable, Checkout Password
        $result = Invoke-RestMethod -Method Post -body $json -Uri $checkin -ContentType application/json
        $result
        Invoke-RestMethod -Method Post -body $json -Uri $checkout -ContentType application/json | Out-Null
        # Disconnect Session and Return
        Invoke-RestMethod -Method Post -Body $json -Uri $logout -ContentType application/json | Out-Null
    }
}

$Output = Get-ErpmSharedPassword -AccountName $AccountName -SystemName $SystemName -PasswordList $PasswordList -Environment $Environment -Credential $Credential -Comment $Comment
if($ReturnType -eq "PlainText"){
    $Output
}elseif($ReturnType -eq "PSCredential"){
    $secpasswd = ConvertTo-SecureString $Output.Password -AsPlainText -Force
    $CredObject = New-Object System.Management.Automation.PSCredential ($AccountName, $secpasswd)
    $CredObject
}