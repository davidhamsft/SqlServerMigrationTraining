targetScope = 'subscription'

@description('Enter a resource group name.')
param rgName string = 'SQLMigrationLab'

@description('Choose a location')
@allowed(loadJsonContent('azure-bicep-locations/locations.json', '$.[*].name'))
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
  8
  16
  24
  32
  40
  64
  80
])
param vCores int = 16

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

module lab 'lab.bicep' = {
  name: 'labDeployment'
  scope: rg
  params: {
    vmName: vmName
    vmSize: vmSize
    location: location
    managedInstanceName: managedInstanceName
    sqlDBServerName: sqlDBServerName
    sqlDBDatabaseName: sqlDBDatabaseName
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    virtualNetworkName: virtualNetworkName
    addressPrefix: addressPrefix
    bastionHostName: bastionHostName
    bastionSubnetIpPrefix: bastionSubnetIpPrefix
    sqlMiSubnetName: sqlMiSubnetName
    sqlMiSubnetPrefix: sqlMiSubnetPrefix
    vmSubnetName: vmSubnetName
    vmSubnetPrefix: vmSubnetPrefix
    skuName: skuName
    vCores: vCores
    storageSizeInGB: storageSizeInGB
    licenseType: licenseType
  }
}
