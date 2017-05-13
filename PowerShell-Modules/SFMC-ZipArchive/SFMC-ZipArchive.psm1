function Expand-ZipFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [string]$SourceFile,
        [Parameter(Mandatory=$true)]
        [string]$Destination,
        [Parameter(Mandatory=$false)]
        [Switch]$DoNotCreateDestination,
        [Parameter(Mandatory=$false)]
        [Switch]$OverwriteExisting,
        [Parameter(Mandatory=$false)]
        [Switch]$HideOutput
    )

    begin {
        $bProceed = $true
        if ((Test-Path $Destination -PathType 'Container') -eq $false) {
            if ($DoNotCreateDestination) {
                Write-Warning "Cannot extract the file because the destination does not exist and will not be created per inputed parameters."
                $bProceed = $false
                return
            }else{
                try {
                    Write-Host "Creating $Destination as it does not exist."
                    New-Item -Path $Destination -ItemType Directory -Force | Out-Null
                }
                catch {
                    Write-Host "An error occured creating the destination directory, no changes have been made." -ForegroundColor Red -BackgroundColor Black
                    Write-Error $_
                    $bProceed = $false
                    return
                }
            }
        }
        $iOption = 0
        if ($OverwriteExisting) {
            $iOption = $iOption + 16
        }
        if ($HideOutput) {
            $iOption = $iOption + 4
        }
    }

    process {
        if ($bProceed) {
            $ErrorCount = 0
            $shell = New-Object -com Shell.Application
            $zip = $shell.NameSpace($SourceFile)
            foreach($item in $zip.Items())
            {
                $destinationFile = $null
                $destinationExt = $null
                $destinationExt = $item.Path.Substring($item.Path.LastIndexOf('.'))
                $destinationFile = Join-Path -Path ($Destination) -ChildPath ("$($item.Name)$destinationExt")
                try {
                    Write-Host ""
                    Write-Host "Extracting to $destinationFile" -ForegroundColor Cyan
                    $shell.Namespace($Destination).CopyHere($item,$iOption)
                }
                catch {
                    Write-Host "An error occured while unziping a file.  This file will be skipped." -ForegroundColor Red -BackgroundColor Black
                    Write-Error $_
                    $ErrorCount++
                }
            } 
        }
    }
    
    end {
        if ($bProceed) {
            if ($ErrorCount -eq 0) {
                Write-Host "Processing complete without error." -ForegroundColor Green
            }elseif ($ErrorCount -eq 1) {
                Write-Warning "Processing completed with 1 error."
            }else{
                Write-Warning "Processing completed with $ErrorCount errors."
            }      
        }
    }
}
