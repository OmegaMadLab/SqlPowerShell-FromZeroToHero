#region SQL Server SMO

# SQL Server Management Objects (SMO) is a collection of objects that are designed for programming all aspects of managing Microsoft SQL Server
# https://docs.microsoft.com/it-it/sql/relational-databases/server-management-objects-smo/sql-server-management-objects-smo-programming-guide?view=sql-server-ver15

#region library loading script 
# Loads the SQL Server Management Objects (SMO) - old school version.
# You can also load them by loading SqlServer PowerShell module
#  
  
$ErrorActionPreference = "Stop"  
  
$sqlpsregItem = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds" -ErrorAction "SilentlyContinue" |
                    ? PSChildName -like "Microsoft.SqlServer.Management.PowerShell.sqlps*" 

 
if (!$sqlpsregItem)  
{  
    throw "SQL Server Provider for Windows PowerShell is not installed."  
}  
else  
{  
    $item = Get-ItemProperty $sqlpsregItem.PSPath
    $sqlpsPath = [System.IO.Path]::GetDirectoryName($item.Path)  
}  
  
$assemblylist =   
"Microsoft.SqlServer.Management.Common",  
"Microsoft.SqlServer.Smo",  
"Microsoft.SqlServer.Dmf ",  
"Microsoft.SqlServer.Instapi ",  
"Microsoft.SqlServer.SqlWmiManagement ",  
"Microsoft.SqlServer.ConnectionInfo ",  
"Microsoft.SqlServer.SmoExtended ",  
"Microsoft.SqlServer.SqlTDiagM ",  
"Microsoft.SqlServer.SString ",  
"Microsoft.SqlServer.Management.RegisteredServers ",  
"Microsoft.SqlServer.Management.Sdk.Sfc ",  
"Microsoft.SqlServer.SqlEnum ",  
"Microsoft.SqlServer.RegSvrEnum ",  
"Microsoft.SqlServer.WmiEnum ",  
"Microsoft.SqlServer.ServiceBrokerEnum ",  
"Microsoft.SqlServer.ConnectionInfoExtended ",  
"Microsoft.SqlServer.Management.Collector ",  
"Microsoft.SqlServer.Management.CollectorEnum",  
"Microsoft.SqlServer.Management.Dac",  
"Microsoft.SqlServer.Management.DacEnum",  
"Microsoft.SqlServer.Management.Utility"  
  
foreach ($asm in $assemblylist)  
{  
    $asm = [Reflection.Assembly]::LoadWithPartialName($asm)  
}  
  
Push-Location  
Set-Location "$sqlpsPath\..\PowerShell\Modules\SQLPS"
update-FormatData -prependpath SQLProvider.Format.ps1xml   
Pop-Location

#endregion

# Variables, arrays, objects
$null -eq $var

$var = 5
Get-Member -InputObject $var
$var.GetType().FullName

$var = "text"
$var.GetType().FullName

# Connect to SQL instances on DEMO-SQL-0 and explore properties and methods
$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList 'demo-sql-0'

Get-Member -InputObject $sqlServer
$sqlServer | Get-Member

$sqlServer.GetSqlServerVersionName()
$sqlServer.EngineEdition

# Collection of objects
$sqlServer.Databases

# Different kind of visualization + Piping
$sqlServer.Databases | Format-List -Property *
$sqlServer.Databases | Format-List Name, CompatibilityLevel, Size
$sqlServer.Databases | Format-Table Name, CompatibilityLevel, Size
$sqlServer.Databases | 
    Format-Table Name, CompatibilityLevel, @{Name="SizeKB"; Expression={[math]::Round($_.Size*1KB, 1)}}

# Pick only some elements of the collection - similar to an array
$sqlServer.Databases[0]
$sqlServer.Databases | Sort-Object Name | Select-object -First 2

<# 
Filtering

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
$sqlServer.Databases | Where-Object Name -Like 'ma*'
$sqlServer.Databases | ? CompatibilityLevel -gt 130

# Variable evaluation - double quote and single quote
$string = "This is a string"

Write-Host 'My variable contains: $string'
Write-Host "My variable contains: $string"
Write-Host "My string contains $($string.Length) chars"

Write-Host "My instance contains these DBs: $($sqlServer.Databases -join ',')"

foreach ($database in $sqlServer.Databases) {
    Write-Host "Collation for database $($database.Name) is $($database.Collation)."
}

$sqlServer.Databases | ForEach-Object {
    Write-Host "Collation for database $($_.Name) is $($_.Collation)."
}

# Create a new SQL login
$sqlServer.Logins 

$login = [Microsoft.SqlServer.Management.Smo.login]::new($sqlServer, 'newSqlLogin')
$login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
$login.PasswordPolicyEnforced = $false
$login.Create('$str0ngPassw0rd')

$login.GetType().FullName

$sqlServer.Logins | Where-Object Name -eq newSqlLogin | fl

# Rename the login
$login.Rename("renamedLogin")
$sqlServer.Logins.Refresh()
$sqlServer.Logins | Where-Object Name -eq newSqlLogin 
$sqlServer.Logins | ? Name -eq renamedLogin

# Script the logins
$sqlServer.logins | % { $_.Script() } | Out-File .\logins.sql
code .\logins.sql

#endregion