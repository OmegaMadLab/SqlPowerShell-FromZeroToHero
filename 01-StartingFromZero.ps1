#region Commands and modules

# Get list of available commands
Get-Command

# Get list of available commands for specific noun
Get-Command -Noun DNS*

# Get help for specific command
Get-Help Set-DnsClient
Get-Help Set-DnsClient -Examples
Get-Help Set-DnsClient -Full

# Alias
Get-Command -Name dir
Get-Alias

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

