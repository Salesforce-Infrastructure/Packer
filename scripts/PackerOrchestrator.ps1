<#
    See PO-ResultObject.ps1 for the object that is returned from the PO-xxxxxx.ps1 scripts.
    This object needs to be a part of all scripts called by PackerOrchestrator.
    
    EXAMPLE USAGE IN SCRIPT
    $<ResultObjectName> = $null
    C:\PackerScripts\PO-ResultObject.ps1
    $<ResultObjectName> = Import-Clixml -Path ".\PO-ResultObject.xml"
#>

if(Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Startup"){
    Write-Output "PackerOrchestratorStart script exists in the startup directory, no action is needed."
}else{
    Write-Output "Copying PackerOrchestratorStart script to the All Users Startup directory."
    Copy-Item -Path "C:\PackerScripts\PackerOrchestratorStart.bat" -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" -Force
    Write-Output "Copy completed successfully."
}
Write-Output "Disabling WinRM using the Set-RemoteMgmt script."
C:\PackerScripts\Set-RemoteMgmt.ps1 -Disable

$OS = Get-WmiObject Win32_OperatingSystem
if ($OS.Caption.StartsWith("Microsoft Windows Server 2016")){
    Write-Output "Building the script list for Server 2016."
    $requiredPath = "C:\PackerScripts\_OrchestrationFiles\2016-Required.po"
    $completedPath = "C:\PackerScripts\_OrchestrationFiles\2016-Completed.po"
}elseif ($OS.Caption.StartsWith("Microsoft Windows Server 2012")) {
    Write-Output "Building the script list for Server 2012 R2."
    $requiredPath = "C:\PackerScripts\_OrchestrationFiles\2012R2-Required.po"
    $completedPath = "C:\PackerScripts\_OrchestrationFiles\2012R2-Completed.po"
}elseif ($OS.Caption.StartsWith("Microsoft Windows Server 2008 R2")){
    Write-Output "Building the script list for Server 2008 R2."
    $requiredPath = "C:\PackerScripts\_OrchestrationFiles\2008R2-Required.po"
    $completedPath = "C:\PackerScripts\_OrchestrationFiles\2008R2-Completed.po"
}

Write-Output "Processing scripts."
$Required = Get-Content $requiredPath
$Completed = Get-Content $completedPath
foreach($line in $Required){
    $Result = $null
    if ($Completed -contains $line) {
        Write-Output "$($line.Substring(2)) has already been attempted and will not rerun."
    }else{
        $Completed = Get-Content $completedPath
        $cmd = $line.Substring(2)
        Write-Output "Running $cmd"
        $Result = & $cmd
        if ($Result.Reboot -eq $true -and $Result.Completed -eq $true) {
            Write-Output "$cmd completed and a restart is required, logging this before proceeding with the reboot."
            Add-Content $completedPath $line
            Start-Sleep -Seconds 10
            Restart-Computer -Force
            exit
        }elseif($Result.Reboot -eq $false -and $Result.Completed -eq $false){
            Write-Output "$cmd completed but did not return a completion notifcation or reboot notification. This could be a sign of a script failure or bug. The script will be re-ran on reboot."
            Start-Sleep 10
            Restart-Computer -Force
            exit
        }elseif($Result.Reboot -eq $true -and $Result.Completed -eq $false){
            Write-Output "$cmd requires a reboot to continue. This is common, especially for Windows Updates.  Rebooting now."
            Start-Sleep -Seconds 10
            Restart-Computer -Force
            exit
        }elseif($Result.Reboot -eq $false -and $Result.Completed -eq $true ){
            Write-Output "$cmd completed and does not require a reboot. Moving on."
            Add-Content $completedPath $line
        }
        else{
            Write-Output "An unexpected output was received from $cmd. The computer will reboot and try again in the event that a random error was observed."
            Start-Sleep -Seconds 10
            Restart-Computer -Force
            exit
        }
    }
}
Write-Output "PackerOrchestrator is complete.  Re-enabling WinRM and deleting startup object."
Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\PackerOrchestratorStart.bat" -Force -ErrorAction SilentlyContinue
C:\PackerScripts\Set-RemoteMgmt.ps1 -Enable -DelayedAuto