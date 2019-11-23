# Demo Environment cleanup script

Remove-SmbShare -Name "DbaBackup" -Force
Remove-Item "F:\DbaBackup" -Force -Recurse
Remove-DbaDatabase -SqlInstance "DEMO-SQL-0\NAMED", "DEMO-SQL-0" -Database "DBAMaintenance", "UserDatabase" -Confirm:$false
Remove-DbaLogin -SqlInstance "DEMO-SQL-0", "DEMO-SQL-1", "DEMO-SQL-0\NAMED" -Login "sqlLogin", "newSqlLogin", "RenamedLogin" -Confirm:$false
Remove-DbaAgDatabase -SqlInstance "DEMO-SQL-0" -Database "UserDatabase" -AvailabilityGroup "demo-sql-ag" -Confirm:$false
Remove-DbaAgDatabase -SqlInstance "DEMO-SQL-0" -Database "UserDatabase2" -AvailabilityGroup "demo-sql-ag2" -Confirm:$false
Remove-DbaAvailabilityGroup -SqlInstance "DEMO-SQL-0" -AvailabilityGroup "demo-sql-ag2" -Confirm:$false
Remove-DbaDatabase -SqlInstance "DEMO-SQL-0", "DEMO-SQL-1" -Database "UserDatabase", "UserDatabase2" -Confirm:$false
Get-DbaAgentJob -SqlInstance "DEMO-SQL-0", "DEMO-SQL-0\NAMED", "DEMO-SQL-1" -ExcludeJob "ExampleBrokenBackup.Subplan_1", "syspolicy_purge_history" | Remove-DbaAgentJob
Set-DbaMaxDop -SqlInstance "DEMO-SQL-0\NAMED" -MaxDop 0
Set-DBAMaxMemory -SQLInstance "DEMO-SQL-0\NAMED"-Max 2147483647

Remove-Item ".\dir.CSV" -Force
Remove-Item ".\logins.sql" -Force
Remove-Item ".\ScanResult.xlsx" -Force
Remove-Item ".\*.txt" -Force
Remove-Item ".\secedit.jfm" -Force
Remove-Item ".\secedit.sdb" -Force

$sqlNamedInst = Connect-DbaInstance -sqlInstance "DEMO-SQL-0\NAMED"
$sqlNamedInst.Settings.LoginMode = [Microsoft.SqlServer.Management.SMO.ServerLoginMode]::Integrated
# Make the changes
$sqlNamedInst.Alter()
Restart-DbaService -ComputerName "DEMO-SQL-0" -Instance "NAMED"

Remove-Item ".\dir.CSV" -Force
Remove-Item ".\logins.sql" -Force
Remove-Item ".\ScanResult.xlsx" -Force
Remove-Item ".\*.txt" -Force
# Remove IFI and LPIM privilege to sqlsvc
