#region DBATools module

# DBATools is an awesome module created by Chrissy LeMaire @cl
# It's now maintenaned and expanded by the community, and anyone can contribute on it.
# It require a client with PowerShell 3.0+ and Windows 7+ and it works with SQL Server 2000+
#
# https://dbatools.io

# Install or update module from PSGallery
if(!(Get-Module -Name dbatools -ListAvailable)) {
    Install-Module dbatools    
} else {
    Update-Module dbatools
}

# List the available commands
Start-Process -filepath "https://dbatools.io" -WindowStyle Maximized

# List available cmdlets - generic way
Get-Command -Module DbaTools
Get-Command -Module DbaTools | Measure

# List available cmdlets - native way
Find-DbaCommand | Out-GridView
Find-DbaCommand -Tag Backup
Find-dbaCommand -Tag AG
Find-DbaCommand -Pattern memory

# Discover SQL Server instances in various way
Find-DbaInstance -DiscoveryType Domain 
Find-DbaInstance -DiscoveryType IPRange -IpAddress 10.0.1.0/24
Find-DbaInstance -DiscoveryType DataSourceEnumeration

# Pipe with other cmdlets to assess environments
Find-DbaInstance -DiscoveryType Domain | Get-DbaLogin

# Same as before, but using a list of known instances
$instances = @()
$instances += "DEMO-SQL-0"
$instances += "DEMO-SQL-1"

$instances | Connect-DbaInstance | Get-DbaLogin | Out-GridView

# Best practice assessment
Get-DbaPrivilege -ComputerName $instances
Test-DbaMaxDop -SqlInstance $instances
Test-DbaMaxMemory -SqlInstance $instances

function Get-InstanceBestPracticesStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$sqlInstance,

        [Parameter(Mandatory=$false)]
        [string]$logFilePath = ".\BestPracticesStatus.txt"
    )

    "Best practices summary" | Out-File $logFilePath -Force

    $instances | % {
        try {
           Get-DbaPrivilege -ComputerName $_ -EnableException | Out-File $logFilePath -Append
           Test-DbaMaxDop -SqlInstance $_ -EnableException | Out-File $logFilePath -Append
           Test-DbaMaxMemory -SqlInstance $_ -EnableException | Out-File $logFilePath -Append
        }
        catch {
            Write-Output "Error while assessing instance $_" | Out-File $logFilePath -Append
        }
    }
}

$instances += "NONEXISTINGSQL"
$instances | Get-InstanceBestPracticesStatus
code .\BestPracticesStatus.txt

# Execute T-SQL
$query = @"  
SELECT  @@ServerName as ServerName,
        name
FROM    sys.databases
"@

Invoke-DbaQuery -sqlInstance "DEMO-SQL-0", "DEMO-SQL-1" -Query $query

# Instance setup and configuration

# Keep track of all command executed
Start-Transcript -Path .\Transcript.txt -Force -IncludeInvocationHeader

$config = @{
    AGTSVCSTARTUPTYPE     = "Automatic"
    SQLCOLLATION          = "Latin1_General_CI_AS"
    BROWSERSVCSTARTUPTYPE = "Automatic"
    FILESTREAMLEVEL       = 0
    FEATURES              = "SQLEngine"
}
Install-DbaInstance -SqlInstance "DEMO-SQL-0\NAMED" `
    -Version 2017 `
    -Path "C:\SQLServerFull" `
    -Configuration $config `
    -verbose

# Post-deployment configuration
Get-DbaService "DEMO-SQL-0.contoso.local" -Instance "NAMED" -Type Engine, Agent | 
    Update-DbaServiceAccount -ServiceCredential (Get-Credential) 

Set-DbaPrivilege -ComputerName "DEMO-SQL-0\NAMED" -Type "IFI", "LPIM"
Set-DbaMaxDop -SqlInstance "DEMO-SQL-0\NAMED" -MaxDop 1
Set-DBAMaxMemory -SQLInstance "DEMO-SQL-0\NAMED" `
    -Max $((Get-DbaMaxMemory -SQLInstance "DEMO-SQL-0").Total - 3072)
# OR #
Set-DBAMaxMemory -SQLInstance "DEMO-SQL-0\NAMED" `
    -Max (Test-DbaMaxMemory -SqlInstance "DEMO-SQL-0").RecommendedValue

# Close transcript
Stop-Transcript
code .\transcript.txt

# Enable SQL Auth - using SMO
$sqlNamedInst = Connect-DbaInstance -sqlInstance "DEMO-SQL-0\NAMED"
$sqlNamedInst.Settings.LoginMode = [Microsoft.SqlServer.Management.SMO.ServerLoginMode]::Mixed
# Make the changes
$sqlNamedInst.Alter()
Restart-DbaService -ComputerName "DEMO-SQL-0" -Instance "NAMED"

# New user database and sql login
$userDb = New-DbaDatabase -name "UserDatabase" -SqlInstance "DEMO-SQL-0\NAMED"

# Create a table and add some sample data
$col1 = @{
    Name        = 'filename'
    Type        = 'nvarcharmax'
    Nullable    = $true
}
$col2 = @{
    Name        = 'size'
    Type        = 'bigint'
    Nullable    = $true
}

New-DbaDbTable -SqlInstance "DEMO-SQL-0\NAMED" `
    -Database $userDb.Name `
    -Schema "dbo" `
    -Name "filelist" `
    -ColumnMap $col1, $col2

Get-ChildItem -File | select Name, Length | Export-Csv .\TableContent.csv -NoTypeInformation
code .\TableContent.csv

Import-DbaCsv -Path ".\TableContent.csv" `
    -SqlInstance "DEMO-SQL-0\NAMED" `
    -Database "UserDatabase" `
    -Schema "dbo" `
    -Table "filelist"

$sqlLogin = New-DbaLogin -Name "sqlLogin" -SqlInstance "DEMO-SQL-0\NAMED"
$sqlLogin.GetType().FullName
# Set sqlLogin as db_datareader on new database
$dbUser = New-DbaDbUser -Database "UserDatabase" `
            -SqlInstance "DEMO-SQL-0\NAMED" `
            -Login $sqlLogin.Name

Add-DbaDbRoleMember -Database "UserDatabase" `
    -SqlInstance "DEMO-SQL-0\NAMED" `
    -User $dbUser.Name `
    -Role "db_datareader" `
    -Confirm:$false

# Test the new sql login and its role
# Get sql login credential
$sqlCred = Get-Credential
# or
$sqlCred = New-Object System.Management.Automation.PSCredential ('sqlLogin', (ConvertTo-SecureString "Passw0rd.123" -AsPlainText -Force))

$sqlCred

Invoke-DbaQuery -SqlInstance "DEMO-SQL-0\NAMED" `
    -Database "userdatabase" `
    -sqlCredential $sqlCred `
    -query "SELECT * FROM dbo.filelist"

Invoke-DbaQuery -SqlInstance "DEMO-SQL-0\NAMED" `
    -Database "userdatabases" `
    -sqlCredential $sqlCred `
    -query "CREATE TABLE DemoTable (ID INT)"

# Install community tools
$maintenanceDb = New-DbaDatabase -SqlInstance "DEMO-SQL-0\NAMED" -Name "DBAMaintenance"

Install-DbaFirstResponderKit -SqlInstance "DEMO-SQL-0\NAMED" -Database $maintenanceDb.Name
Install-DbaWhoIsActive -SqlInstance "DEMO-SQL-0\NAMED" -Database $maintenanceDb.Name

$backupFolder = New-DbaDirectory -SqlInstance "DEMO-SQL-0\NAMED" -Path "F:\DbaBackup"
Install-DbaMaintenanceSolution -SqlInstance "DEMO-SQL-0\NAMED" `
    -Database $maintenanceDb.Name `
    -BackupLocation $backupFolder.Path `
    -CleanupTime 24 `
    -InstallJobs

# Schedule full backup jobs
$fullBackupJob = Get-DbaAgentJob -sqlInstance "DEMO-SQL-0\NAMED" `
                    -Category "Database Maintenance" | 
                    Where-Object { 
                        $_.Name -like '*backup*full*' `
                        -and $_.JobSchedules.count -eq 0 
                    } 
$fullBackupJob

Get-DbaAgentSchedule -SqlInstance "DEMO-SQL-0\NAMED"
$schedule = New-DbaAgentSchedule -SqlInstance "DEMO-SQL-0\NAMED" `
                -Schedule "Daily at midnight" `
                -FrequencyType Daily `
                -FrequencyInterval 24 `
                -StartTime "000000" `
                -Force

$fullBackupJob | Set-DbaAgentJob -ScheduleId $schedule.ID

Get-DbaAgentJob -sqlInstance "DEMO-SQL-0\NAMED" -Category "Database Maintenance" | 
    Where-Object Name -like '*backup*full*' | Select-Object Name, JobSchedules

# Massive backup example
Backup-DbaDatabase -SqlInstance "DEMO-SQL-0\NAMED" -BackupDirectory "F:\DbaBackup" -CopyOnly

# Migrate contents between instances
# Source is DEMO-SQL-0\Named
# Items will be copied to DEMO-SQL-0
# DBs will be joined to Always On AGs
# Items will be synched between replicas

Copy-DbaLogin -Source "DEMO-SQL-0\NAMED" -Destination "DEMO-SQL-0" -ExcludeSystemLogins

Copy-DbaDatabase -Source "DEMO-SQL-0\NAMED" `
    -Destination "DEMO-SQL-0" `
    -BackupRestore `
    -SharedPath "F:\DbaBackup" `
    -AllDatabases

Copy-DbaAgentJobCategory -Source "DEMO-SQL-0\NAMED" -Destination "DEMO-SQL-0"

Copy-DbaAgentJob -Source "DEMO-SQL-0\NAMED" -Destination "DEMO-SQL-0"

# Availability group management
# Add a new DB to existing AG
Get-DbaAvailabilityGroup -SqlInstance "DEMO-SQL-0"

# Check if local node is primary replica for each AG, otherwise failover
$ags = Get-DbaAvailabilityGroup -SqlInstance "DEMO-SQL-0"
foreach($ag in $ags) {
    if($ag.PrimaryReplica -ne $env:COMPUTERNAME) {
        $ag | Invoke-DbaAgFailover
    }
}

# Create a share on local DB folder
$acl = Get-Acl "F:\DbaBackup"
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("CONTOSO\sqlsvc", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.SetAccessRule($AccessRule)
$acl | Set-Acl "F:\DbaBackup"
New-SmbShare -Path "F:\DbaBackup" -Name "DBABackup" -FullAccess "EveryOne"

# Add UserDatabase to AG
Add-DbaAgDatabase -SqlInstance "DEMO-SQL-0" `
    -AvailabilityGroup "demo-sql-ag" `
    -Database "UserDatabase" `
    -SeedingMode Manual `
    -SharedPath "\\DEMO-SQL-0\DBABackup"

Get-DbaAgDatabase -SqlInstance "DEMO-SQL-0" | Out-GridView

# Add a new DB to a new AG
New-DbaDatabase -SqlInstance "DEMO-SQL-0" -Name "UserDatabase2"

Backup-DbaDatabase -SqlInstance "DEMO-SQL-0" `
    -Database "UserDatabase2" `
    -BackupDirectory "F:\DbaBackup"

New-DbaAvailabilityGroup -Primary "DEMO-SQL-0" `
    -Secondary "DEMO-SQL-1" `
    -Name "demo-sql-ag2" `
    -ClusterType Wsfc `
    -AvailabilityMode SynchronousCommit `
    -FailoverMode Automatic `
    -Database "UserDatabase2" `
    -SeedingMode Manual `
    -SharedPath "\\DEMO-SQL-0\DBABackup" -verbose

Get-DbaAvailabilityGroup -SqlInstance "DEMO-SQL-0"
Get-DbaAgDatabase -SqlInstance "DEMO-SQL-0" | Out-GridView

# Sync logins, agent jobs and other relevant items between replicas
Sync-DbaAvailabilityGroup -Primary "DEMO-SQL-0" -AvailabilityGroup "demo-sql-ag"
Sync-DbaAvailabilityGroup -Primary "DEMO-SQL-0" -AvailabilityGroup "demo-sql-ag2"

#endregion
