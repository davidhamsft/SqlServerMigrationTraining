targetScope = 'subscription'

@description('Enter a resource group name.')
param rgName string = 'SQLMigrationLab'

@description('Choose a location')
@allowed([
  'eastus'
  'eastus2'
  'southcentralus'
  'westus2'
  'westus3'
  'australiaeast'
  'southeastasia'
  'northeurope'
  'swedencentral'
  'uksouth'
  'westeurope'
  'centralus'
  'southafricanorth'
  'centralindia'
  'eastasia'
  'japaneast'
  'koreacentral'
  'canadacentral'
  'francecentral'
  'germanywestcentral'
  'norwayeast'
  'switzerlandnorth'
  'uaenorth'
  'brazilsouth'
  'eastus2euap'
  'qatarcentral'
  'centralusstage'
  'eastusstage'
  'eastus2stage'
  'northcentralusstage'
  'southcentralusstage'
  'westusstage'
  'westus2stage'
  'asia'
  'asiapacific'
  'australia'
  'brazil'
  'canada'
  'europe'
  'france'
  'germany'
  'global'
  'india'
  'japan'
  'korea'
  'norway'
  'singapore'
  'southafrica'
  'switzerland'
  'uae'
  'uk'
  'unitedstates'
  'unitedstateseuap'
  'eastasiastage'
  'southeastasiastage'
  'eastusstg'
  'southcentralusstg'
  'northcentralus'
  'westus'
  'jioindiawest'
  'centraluseuap'
  'westcentralus'
  'southafricawest'
  'australiacentral'
  'australiacentral2'
  'australiasoutheast'
  'japanwest'
  'jioindiacentral'
  'koreasouth'
  'southindia'
  'westindia'
  'canadaeast'
  'francesouth'
  'germanynorth'
  'norwaywest'
  'switzerlandwest'
  'ukwest'
  'uaecentral'
  'brazilsoutheast'
])
param location string

@description('Enter SQL Migration Lab VM Name.')
param vmName string

@description('Default VM Size')
param vmSize string = 'Standard_D2_v3'

@description('Enter managed instance name.')
param managedInstanceName string

@description('Enter the SQL DB Logical Server name.')
param sqlDBServerName string

@description('Enter the SQL DB Database name.')
param sqlDBDatabaseName string

@description('Enter user name, this will be your VM Login, SQL DB Admin, and SQL MI Admin')
param administratorLogin string

@description('Enter password, this will be your VM Password, SQL DB Admin Password, SQL MI Admin Password, and sa Password')
@secure()
param administratorLoginPassword string

@description('Enter virtual network name. If you leave this field blank name will be created by the template.')
param virtualNetworkName string = 'SQLMigrationLab-vNet'

@description('Enter virtual network address prefix.')
param addressPrefix string = '10.217.0.0/16'

@description('Enter the Bastion host name.')
param bastionHostName string

@description('Bastion subnet IP prefix MUST be within vnet IP prefix address space')
param bastionSubnetIpPrefix string = '10.217.2.0/24'

@description('Enter Managed Instance subnet name.')
param sqlMiSubnetName string = 'ManagedInstance'

@description('Enter subnet address prefix.')
param sqlMiSubnetPrefix string = '10.217.1.0/24'

@description('Enter Managed Instance subnet name.')
param vmSubnetName string = 'VMSubnet'

@description('Enter subnet address prefix.')
param vmSubnetPrefix string = '10.217.3.0/24'

@description('Enter sku name.')
@allowed([
  'GP_Gen5'
])
param skuName string = 'GP_Gen5'

@description('Enter number of vCores.')
@allowed([
  4
  8
  16
  24
  32
  40
  64
  80
])
param vCores int = 4

@description('Enter storage size.')
@minValue(32)
@maxValue(8192)
param storageSizeInGB int = 256

@description('Enter license type.')
@allowed([
  'BasePrice'
  'LicenseIncluded'
])
param licenseType string = 'LicenseIncluded'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module network 'network.bicep' = {
  name: 'labNetworkDeployment'
  scope: rg
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    addressPrefix: addressPrefix
    bastionSubnetIpPrefix: bastionSubnetIpPrefix
    sqlMiSubnetName: sqlMiSubnetName
    sqlMiSubnetPrefix: sqlMiSubnetPrefix
    vmSubnetName: vmSubnetName
    vmSubnetPrefix: vmSubnetPrefix
    bastionHostName: bastionHostName
  }
}

module labvm 'labvm.bicep' = {
  name: 'labVmDeployment'
  scope: rg
  params: {
    vmName: vmName
    vmSize: vmSize
    location: location
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    vmSubnetName: vmSubnetName
  }
  dependsOn: [
    network
  ]
}

module sqldb 'sqldb.bicep' = {
  name: 'sqlDbDeployment'
  scope: rg
  params: {
    location: location
    sqlDBServerName: sqlDBServerName
    sqlDBDatabaseName: sqlDBDatabaseName
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

module dbmi 'dbmi.bicep' = {
  name: 'dbmiDeployment'
  scope: rg
  params: {
    location: location
    managedInstanceName: managedInstanceName
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    sqlMiSubnetName: sqlMiSubnetName
    skuName: skuName
    vCores: vCores
    storageSizeInGB: storageSizeInGB
    licenseType: licenseType
  }
  dependsOn: [
    network
  ]
}

module storage 'storage.bicep' = {
  name: 'storageAccountDeployment'
  scope: rg
  params: {
    location: location
  }
}
