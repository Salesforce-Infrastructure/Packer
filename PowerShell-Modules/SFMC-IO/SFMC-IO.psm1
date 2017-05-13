function Get-ShortName 
{
<#
.SYNOPSIS

    Get's the ShortName of a directory or file.
.DESCRIPTION

    Get's the ShortName of a directory or file.
.PARAMETER Path

    The path to get the shortname of.  By default, this will return the current directory.
.PARAMETER ReturnObject

    Return a 'Get-Item' object for the output instead of the default string path.
.EXAMPLE

    Get-ShortName
    This will return the shortname, if applicable, to the current directory.
.EXAMPLE

    Get-ShortName -Path "C:\Program Files (x86)"
    Returns:    C:\PROGRA~2
.EXAMPLE

    Get-ShortName -Path "C:\Program Files (x86)\Common Files\Microsoft Shared\MSInfo\msinfo32.exe"
    Returns:    C:\PROGRA~2\COMMON~1\MICROS~1\MSInfo\msinfo32.exe
.EXAMPLE

    Get-ShortName -Path "C:\Program Files (x86)\Common Files\Microsoft Shared\MSInfo\msinfo32.exe" -ReturnObject
    Returns:

            Directory: C:\Program Files (x86)\Common Files\Microsoft Shared\MSInfo


    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----        7/16/2016   7:42 AM         336896 msinfo32.exe
.EXAMPLE

    Get-ChildItem -Path "C:\Program Files\" | foreach-object {$_.FullName}
    Returns the shortname of each file or folder in 'C:\Program Files'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]$Path=(Get-Item ".").FullName,
    [Switch]$ReturnObject
    )
    $Path = (Get-Item $Path).FullName
    $fso = New-Object -ComObject Scripting.FileSystemObject
    $Result = $null
    if ((Get-Item $Path).PSIsContainer){
        $Result = ($fso.GetFolder($Path)).ShortPath
    }else{
        $Result = ($fso.GetFile($Path)).ShortPath
    }
    if ($ReturnObject) {
        $Result = Get-Item $Result
    }
    $Result
}

function Get-FileTail
{
    <#
.SYNOPSIS

    Monitors a file and prints any additional content to the console.
    Aliases:  Tail
.DESCRIPTION

    Monitors a file and prints any additional content to the console.
    Aliases:  Tail
.PARAMETER File

    The path of the file to Tail.
.PARAMETER InitialLines

    The amount of lines to load into the console on first read. Default is 0, which will allow for only new content written after the start of the command to be shown.
    Specifying -1 will load all content of the file into the console initially.  This could cause performance impact on larger files.
    Alias:  Lines
.EXAMPLE

    Get-FileTail -File C:\Test.log
    Prints all content of a file that is written after the monitoring starts. 
.EXAMPLE

    Get-FileTail -File C:\Test.log -InitialLines -1
    Prints all existing and new content of a file to the console.
.EXAMPLE

    Get-FileTail -File C:\Test.log -InitialLines 5
    Prints the last 5 lines and new content of a file to the console.
.EXAMPLE

    Tail -File C:\Test.log
    Functions the same as the first example, simply uses the 'Tail' alias for this function.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [string]$File,
        [Parameter(Mandatory=$false)]
        [Alias("Lines")]
        [int32]$InitialLines=0
    )
    # Using cat instead of Get-Content to further make this 'Linuxy'
    if ($InitialLines -eq -1) {
        Write-Host "Starting monitoring of $File with all existing content to be loaded first." -ForegroundColor Yellow
    }else{
        Write-Host "Starting monitoring of $File with $InitialLines initial lines to be loaded first." -ForegroundColor Yellow
    }
    Write-Host "Press CTRL + C to cancel this operation." -ForegroundColor Yellow
    Write-Host ""
    Write-Host ""
    try {
        cat $File -Wait -Tail $InitialLines
    }
    catch {
        Write-Host ""
        Write-Host ""
        Write-Host "The process was interrupted:" -ForegroundColor Red -BackgroundColor Black
        $_.Exception
    }finally{
        Write-Host ""
        Write-Host ""
        Write-Host "Finished tailing $File" -ForegroundColor Yellow
    }
}
New-Alias -Name Tail -Value Get-FileTail -Scope Global