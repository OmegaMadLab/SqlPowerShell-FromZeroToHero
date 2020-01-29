#region SQL Server SMO

# SQL Server Management Objects (SMO) is a collection of objects that are designed for programming all aspects of managing Microsoft SQL Server
# https://docs.microsoft.com/it-it/sql/relational-databases/server-management-objects-smo/sql-server-management-objects-smo-programming-guide?view=sql-server-ver15

#  
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

# Connect to SQL instances on DEMO-SQL-0 and explore properties and methods
$sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList 'demo-sql-0'

$sqlServer.GetSqlServerVersionName()
$sqlServer.EngineEdition
$sqlServer.Databases

$sqlServer.Databases | ForEach-Object {
    Write-Host "Collation for database $($_.Name) is $($_.Collation). Compatibility level is $($_.CompatibilityLevel)."
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
notepad .\logins.sql

#endregion