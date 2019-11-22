#region Commands and modules

# Get list of available commands
Get-Command

# Alias
Get-Command -Name dir
Get-Alias

# Get list of available commands for specific noun
Get-Command -Noun DNS*

# Get help for specific command
Get-Help Set-DnsClient
Get-Help Set-DnsClient -Examples
Get-Help Set-DnsClient -Full

# Get modules
Get-Module # Online loaded

$env:PsModulePath

Get-Module -ListAvailable # All modules installed on current machine

# Import module already installed
Import-Module Az.Sql

# List modules from remote repositories
Find-Module -filter Azure

# Install or update module from PSGallery
Install-Module Az
Update-Module Az

#endregion

#region Variables, arrays, objects
# Strings
$string = "This is a string"
$string

# A variable is an object with methods and properties
$string | Get-Member

$string.ToUpper()
$string.ToLower()
$string.Contains("This")
$string.Contains("That")
$string.Length

$null -eq $var

$var = 5
$var.GetType().FullName

$var = "text"
$var.GetType().FullName

[int]$var = "5"
$var.GetType().FullName

$var += 1
$var
$var++
$var

# Variable evaluation - double quote and single quote
Write-Host 'My variable contains: $string'
Write-Host "My variable contains: $string"
Write-Host "Today is $((Get-Date).DayOfWeek) and my variable contains $($string.Length) chars"

# multiline strings
$hereString = @"
This is a
multiline string.
In SQL context, it's really
usefull to manage T-SQL text.
Today is {0} {1}
"@

$hereString
$hereString.Replace("{0}", (Get-Date).DayOfWeek)
$hereString -f (Get-Date).DayOfWeek, (Get-Date).Day

# Arrays
$array = "1", "2", "3"
$array

$array = @()
$array += "4"
$array += "5"
$array += "6"
$array

$array = $string.Split(" ")
$array

$array[1]
$array.Count

$array -join " "

# Hash tables
$hash = @{
            "key1" = "value1"
            "key2" = "value2"
         }

$hash
$hash | Get-Member
$hash["key2"]
$hash.key1

# Custom object
$rectangle = [PSCustomObject]@{
    Height = ""
    Width = ""
}

$scriptBlock = {
    
    try {
        $this.Height * $this.Width
    }
    catch {
        Write-Error "Please insert values for Width and Height."
    }

}

$rectangle | Add-Member -Name "Area" -MemberType ScriptMethod -Value $scriptBlock

$rectangle | Get-Member

$rectangle.Width = 2
$rectangle.Height = 3
$rectangle.Area()

#endregion

#region Comparison

<# 

comparison operators https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators?view=powershell-6

-eq --> equal
-ne --> not equal
-gt --> greater than
-ge --> equal or greater than
-lt --> less than
-le --> equal or less than
-contains
-notcontains
-match
-notmatch
-like
-notlike
-is
-isnot
-in
-notin
-replace

#>

1 -eq 1
1 -ne 1
3 -ge 3
3 -gt 3
"This is a string" -like "*is*"

#endregion

#region Conditional logic

# IF ... ELSE statement
$a = 1
if($a -gt 2) {
    Write-Host "A is greater than 2"
}
else {
    Write-Host "A is less or equal to 2"
}

# SWITCH statement
$a = "string3"
switch ($a) {
    "string1" { Write-Host "A is string1" }
    "string2" { Write-Host "A is string2" }
    Default { Write-Host "None of the above"}
}

#endregion

#region Piping, filtering and presenting output

# Show disks
Get-Disk

# Get partitions for first disk
$disk = Get-Disk | Where-Object { $_.PartitionStyle -eq "MBR" -and $_.Size -gt 120GB }
Get-Partition -disk $disk
# less verbose
Get-Disk | ? { $_.PartitionStyle -eq "MBR" -and $_.Size -gt 120GB } | Get-Partition

# Get info for partition C:
Get-Disk | ? { $_.PartitionStyle -eq "MBR" -and $_.Size -gt 120GB } | Get-Partition | ? DriveLetter -eq "C"
# Better approach :)
Get-Partition -DriveLetter "C"
# View all properties
Get-Partition -DriveLetter "C" | Format-List
# View some of them
Get-Partition -DriveLetter "C" | Format-List "DriveLetter", "Size", "OperationalStatus"
# Same as before, table format
Get-Partition -DriveLetter "C" | Format-Table "DriveLetter", "Size", "OperationalStatus"
# Same as before, custom table
Get-Partition -DriveLetter "C" | ft "DriveLetter", @{Name="SizeGB"; Expression={[math]::Round($_.Size/1GB, 1)}}, "OperationalStatus"
# Same as before, external window - actually works on Windows PowerShell only; it'll be back on PowerShell 7
Get-Partition -DriveLetter "C" | Select "DriveLetter", @{Name="SizeGB"; Expression={[math]::Round($_.Size/1GB, 1)}}, "OperationalStatus" | Out-GridView

#endregion

#region Loop on collection of objects

# Get top 5 running services, sorted by name
$svcs = Get-Service | Where-Object Status -eq "Running" | Sort-Object Name | Select-Object -First 5
$svcs

# for
for ($i = 0; $i -lt $svcs.Count; $i++) {
    Write-Host "Service display name: $($svcs[$i].DisplayName)"    
}

# Do while
$i = 0
do {
    Write-Host "Service display name: $($svcs[$i].DisplayName)"
    $i++
} while ($i -lt $svcs.Count)

# Do until
$i = 0
do {
    Write-Host "Service display name: $($svcs[$i].DisplayName)"
    $i++
} until ($i -eq $svcs.Count)

# ForEach - readability
foreach($svc in $svcs) {
    Write-Host "Service display name: $($svc.DisplayName)"
}

# ForEach-Object - less verbose
$svcs | % { Write-Host "Service display name: $($_.DisplayName)" }

#endregion

#region Multiline statement to increase readability
Format-Volume -DriveLetter "K" -FileSystem "NTFS" -NewFileSystemLabel "TestVolume" -AllocationUnitSize 64KB -Force

# with backtick
Format-Volume -DriveLetter "K" `
    -FileSystem "NTFS" `
    -NewFileSystemLabel "TestVolume" `
    -AllocationUnitSize 64KB `
    -Force

# splatting
$params = @{
    DriveLetter = "K"
    FileSystem = "NTFS"
    NewFileSystemLabel = "TestVolume"
    AllocationUnitSize = 64KB
    Force = $true
}
Format-Volume @params

#endregion

#region Import/Export to files

# Execution transcript for logging purposes
Start-Transcript -Path .\Transcript.txt -Force -IncludeInvocationHeader -
Write-Host "This is a test message"
Get-ChildItem
Write-Host "End"
Stop-Transcript

notepad.exe .\transcript.txt

# Writing output to files
Write-Output "This is a test message" > .\text1.txt
Write-Output "This is a test message2" >> .\text1.txt
notepad.exe .\text1.txt

"This is a test message" | Out-File text2.txt
"This is a test message2" | Out-File -Append text2.txt
notepad.exe .\text2.txt

# Reading text from file
$fileContent = Get-Content .\text1.txt
$fileContent

# Writing to CSV
Get-ChildItem | Select Name, Length
Get-ChildItem | Select Name, Length| Export-Csv -Path .\dir.CSV
notepad .\dir.csv

# Reading from CSV
Get-Content .\dir.CSV

$table = Import-Csv -Path .\dir.CSV
$table

#endregion

#region Powershell Providers
Get-PSProvider
Get-PsDrive

dir Cert:\LocalMachine\my

#endregion

#region Managing credentials
$credential = Get-Credential
$credential

$credential = New-Object System.Management.Automation.PSCredential ('username', (ConvertTo-SecureString "PassW0rd" -AsPlainText -Force))
$credential

#endregion

#region Executing commands on remote systems
# Enable remote commands on local system
Enable-PSRemoting

# Execute a script on a remote system
$credential = Get-Credential

Write-Host "We're currently working on $($env:COMPUTERNAME)"

$scriptBlock = {
    Write-Host "This code is executed on: $($env:COMPUTERNAME)"
}

Invoke-Command -ComputerName "demo-sql-1.contoso.local" `
    -Scriptblock $scriptBlock `
    -Credential $credential

# Open a persisten session on a remote system
$psSession = New-PSSession -ComputerName "demo-sql-1.contoso.local" `
                -Credential $credential

$scriptBlock1 = {
    $a = "Variable updated by ScriptBlock1"
}

Invoke-Command -Session $psSession -ScriptBlock $scriptBlock1

$scriptBlock2 = {
    Write-Host "Variable `$a contains: $a"
}

Invoke-Command -Session $psSession -ScriptBlock $scriptBlock2

$psSession | Remove-PSSession

# Open an interactive remote session
Enter-PSSession -ComputerName "demo-sql-1.contoso.local" `
    -Credential $credential

$env:COMPUTERNAME

Exit-PSSession

$env:COMPUTERNAME

#endregion

#region Functions
function Get-Squared($number) {
    $number * $number
}
Get-Squared
Get-Squared -number 5
Get-Squared -number "aaa"

function Get-Squared {
    [CmdletBinding()]
    param (
        # Integer value for calculation
        [Parameter(Mandatory, ValueFromPipeline)]
        [int]
        $number
    )

    $number * $number

}

Get-Squared
Get-Squared -number 5
5 | Get-Squared

#endregion
