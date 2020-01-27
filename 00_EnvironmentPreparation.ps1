Add-AzAccount

$RgName = "SqlPowerShell-0toHero-Demo-RG"
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

# Create a vnet
New-AzResourceGroupDeployment -TemplateUri https://raw.githubusercontent.com/OmegaMadLab/LabTemplates/master/vnet.json `
    -ResourceGroupName $Rg.ResourceGroupName 

# Create an AD forest
$adDcDeploy = New-AzResourceGroupDeployment -TemplateUri https://raw.githubusercontent.com/OmegaMadLab/LabTemplates/master/addc.json `
                -ResourceGroupName $Rg.ResourceGroupName `
                -domainName $domain `
                -adminUsername $domainAdmin `
                -adminPassword $domainAdminPwd `
                -envPrefix "Demo" `
                -vmName "ADDC" `
                -vnetName "vnet" `
                -subnetName "defaultSubnet"

# Create a new subnet for member server
$vnet = Get-AzVirtualNetwork -Name "vnet" `
            -ResourceGroupName $Rg.ResourceGroupName

$vnet.DhcpOptions.DnsServers = $adDcDeploy.Outputs.dcPrivateIp.Value

$vnet | Set-AzVirtualNetwork

New-AzResourceGroupDeployment -TemplateUri https://raw.githubusercontent.com/OmegaMadLab/azure-quickstart-templates/master/301-sql-alwayson-md-ilb-zones/azuredeploy.json `
    -ResourceGroupName $rg.ResourceGroupName `
    -namePrefix "demo" `
    -location "westeurope" `
    -vmSize "Standard_B4ms" `
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
    -existingSubnetName $vnet.Subnets[0].Name `
    -enableOutboundInternet "Yes" `
    -_artifactsLocation https://raw.githubusercontent.com/OmegaMadLab/azure-quickstart-templates/master/301-sql-alwayson-md-ilb-zones