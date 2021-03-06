#region SqlServer module

# SqlServer module is the official PowerShell module for SQL Server, and can be obtained from PSGallery. 
# It replaces SQLPS module, still shipped with the product for backward compatibility but not updated anymore.
# It works with all supported SQL Server versions, and required PowerShell 5.0.
#
# https://docs.microsoft.com/en-us/powershell/module/sqlserver/?view=sqlserver-ps

# Install or update module from PSGallery
if(!(Get-Module -Name SqlServer -ListAvailable)) {
    Install-Module SqlServer    
} else {
    Update-Module SqlServer
}

Start-Process -filepath "https://docs.microsoft.com/en-us/powershell/module/sqlserver/?view=sqlserver-ps" -WindowStyle Maximized

# Get commands available in the module
Get-Command -Module SqlServer

Get-Command -Module SqlServer | Measure-Object

# Exploring SQLSERVER provider
Get-PSProvider
Get-PsDrive

dir SQLSERVER:\SQL\DEMO-SQL-0\default

# Managing logins with SQLSERVER provider
$logins = Get-ChildItem SQLSERVER:\SQL\DEMO-SQL-0\default\logins

$logins
($logins | select -first 1).GetType().FullName # <-- Logins are SMO objects

# Managing logins with cmdlet
$logins = Get-SqlLogin -ServerInstance DEMO-SQL-0
$logins
($logins | select -first 1).GetType().FullName

# Execute T-SQL in a sqlcmd-like way
$query = @"  
SELECT  @@ServerName as ServerName,
        name
FROM    sys.databases
"@

Invoke-Sqlcmd -ServerInstance DEMO-SQL-0 -Database MASTER -Query $query

# Dynamic T-SQL creation and execution in a single line
$query = @"
SELECT 'USE ' +
        QUOTENAME(Name) +
        '; SELECT DB_NAME(), Name FROM sys.tables' AS QueryText
FROM sys.databases
"@

(Invoke-Sqlcmd -ServerInstance DEMO-SQL-0 -Database MASTER -Query $query).QueryText | % { Invoke-Sqlcmd -ServerInstance DEMO-SQL-0 -Query $_ }

# Executing a vulnerability assessment at database level
$vaScan = Invoke-SqlVulnerabilityAssessmentScan -ServerInstance DEMO-SQL-0 -DatabaseName Master -ScanId MyVaScan
$vaScan

$vaScan | Export-SqlVulnerabilityAssessmentScan -FolderPath ".\ScanResult.xlsx"

# Executing a sql assessment at different scopes
Get-SqlInstance -ServerInstance DEMO-SQL-0 | Invoke-SqlAssessment
Get-SqlDatabase -ServerInstance DEMO-SQL-0 | Invoke-SqlAssessment

# Getting SQL Agent Jobs informations
Get-SqlAgentJob -ServerInstance DEMO-SQL-0

$job = Get-SqlAgentJob -ServerInstance DEMO-SQL-0 | ? Name -like '*backup*'
Get-SqlAgentJobHistory -ServerInstance DEMO-SQL-0 -JobID $job.JobID

# Exploring ERRORLOG
Get-SqlErrorLog -ServerInstance DEMO-SQL-0 -Since Yesterday 
Get-SqlErrorLog -ServerInstance DEMO-SQL-0 -Since Yesterday | ? Text -like 'ERROR:*'
Get-SqlErrorLog -ServerInstance DEMO-SQL-0 -Since Yesterday | ? Source -eq "Backup"


#endregion
