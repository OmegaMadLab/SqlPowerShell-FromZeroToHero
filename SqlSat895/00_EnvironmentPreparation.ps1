Add-AzAccount

$RgName = "SqlSat895-Demo-RG"
$Location = "West Europe"
$domain = "contoso.local"
$domainAdmin = "contosoadmin"
$domainAdminPwd = (ConvertTo-SecureString "Passw0rd.123" -AsPlainText -Force)

# Get or create resource group
try {
    $Rg = Get-AzResourceGroup -Name $RgName -ErrorAction Stop
} catch {
    $Rg = New-AzResourceGroup -Name $RgName -Location $Location
}

# Create an AD forest with 2 DC by using a quickstart gallery template
New-AzResourceGroupDeployment -TemplateUri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/active-directory-new-domain-ha-2-dc/azuredeploy.json `
    -ResourceGroupName $Rg.ResourceGroupName `
    -domainName $domain `
    -adminUsername $domainAdmin `
    -adminPassword $domainAdminPwd `
    -dnsPrefix ("salsat895-demo-" + (Get-Random -Maximum 99999)) `
    -pdcRDPPort 59990 `
    -bdcRDPPort 59991 `
    -location $Rg.Location

# To reduce lab costs, deallocate VMs created before and reduce their size and tier of disks
$adVm = Get-AzVm -ResourceGroupName $Rg.ResourceGroupName |
            ? Name -like 'ad*'

$adVmJob = $adVm | Stop-AzVm -Force -asJob

While (($adVmJob | Get-Job).State -ne "Completed") {
    Start-Sleep -Seconds 1
}

$adVmIp = @()

$adVm | % { $_.HardwareProfile = "Standard_B2s"}
$adVm | % {
    $diskUpdate = New-AzDiskUpdateConfig -SkuName "StandardSSD_LRS" 
    Update-AzDisk -ResourceGroupName $rg.ResourceGroupName -DiskName $_.StorageProfile.OsDisk.Name -DiskUpdate $diskUpdate
    $_.StorageProfile.DataDisks | % { Update-AzDisk -ResourceGroupName $rg.ResourceGroupName -DiskName $_.Name -DiskUpdate $diskUpdate }
    $adVmIp += ($_.NetworkProfile.NetworkInterfaces[0].Id | Get-AzNetworkInterface).IpConfigurations[0].PrivateIpAddress
}

$adVm | Update-AzVM
$adVm | Start-AzVm -AsJob

# Create a new subnet for member server
$vnet = Get-AzVirtualNetwork -Name "adVnet" `
            -ResourceGroupName $Rg.ResourceGroupName

$subnet = Add-AzVirtualNetworkSubnetConfig -Name "ServerSubnet" -VirtualNetwork $vnet -AddressPrefix "10.0.1.0/24" 

$vnet.DhcpOptions.DnsServers = $adVmIp

$vnet | Set-AzVirtualNetwork

New-AzResourceGroupDeployment -TemplateUri https://raw.githubusercontent.com/OmegaMadLab/azure-quickstart-templates/master/301-sql-alwayson-md-ilb-zones/azuredeploy.json `
    -ResourceGroupName $rg.ResourceGroupName `
    -namePrefix "demo" `
    -location "westeurope" `
    -vmSize "Standard_DS3_v2" `
    -sqlVMImage "SQL2017-WS2016" `
    -sqlVMImageSku "SQLDEV" `
    -vmCount 2 `
    -vmDiskSize 128 `
    -vmDiskCount 2 `
    -existingDomainName $domain `
    -adminUsername $domainAdmin `
    -adminPassword $domainAdminPwd `
    -sqlServiceAccount "sqlsvc" `
    -sqlServicePassword $domainAdminPwd `
    -existingVirtualNetworkRGName $Rg.ResourceGroupName `
    -existingVirtualNetworkName $vnet.Name `
    -existingSubnetName $subnet.Name `
    -enableOutboundInternet "Yes" `
    -_artifactsLocation https://raw.githubusercontent.com/OmegaMadLab/azure-quickstart-templates/master/301-sql-alwayson-md-ilb-zones
