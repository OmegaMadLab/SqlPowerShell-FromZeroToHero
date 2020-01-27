# SQL Server and PowerShell: from Zero To Hero

This repository contains the demo scripts I used during my "Zero to Hero" sessions on SQL Server and PowerShell.

You can generate a demo environment like the one I used during the sessions by using *00_EnvironmentPreparation.ps1* script.
This script generates a lab with a couple of AD domain controllers and a two-nodes Always On Availability Group cluster on your Azure Subscription. 
If you don't have one, a [trial subscription](https://azure.microsoft.com/en-us/free/) with free credits will be more than enough for some tests!

Just log yourself into one of the cluster nodes by using a domain controller as a bridge machine, and proceed over with the demo scripts.

You can find:
- *01-StartingFromZero.ps1*, which contains general examples, starting from the base to arrive on more complex examples
- *02-SqlServerSMO.ps1*, which contains some basic examples based on SQL Management Objects (SMO)
- *03-SqlServerModule.ps1*, which contains demonstrations about [SqlServer](https://docs.microsoft.com/en-us/powershell/module/sqlserver/?view=sqlserver-ps) module
- *04-DbaToolsModule.ps1*, which contains some simple and some hero-level examples with powerfull [DBATools](https://dbatools.io) module

Scripts are meant to be executed block by block, by selecting text and executing it via F8.
By using the DBATools script, you'll install a named instance on primary AG node, with some objects inside it, and you'll migrate it to the Always On AG cluster.

If you want to restart the lab, execute *99_DemoCleanup.ps1* to delete every item created by the scripts.

**Enjoy!**

## Sessions reference
### SQL Saturday 895 - Parma 2019
- [Slides](https://www.slideshare.net/MarcoObinu/sql-saturday-895-sql-server-e-powershell-from-zero-to-hero)
- [Video](https://youtu.be/yR3TfZfzHss) (ITA)

