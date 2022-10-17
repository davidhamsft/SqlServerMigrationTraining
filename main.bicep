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

@description('The name of the Storage Account')
param storageAccountName string = 'store${uniqueString(resourceGroup().id)}'

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

var bastionPublicIpAddressName = '${bastionHostName}-pip'
var bastionSubnetName = 'AzureBastionSubnet'

var networkSecurityGroupName = 'SQLMI-${managedInstanceName}-NSG'
var routeTableName = 'SQLMI-${managedInstanceName}-Route-Table'

var nicName = '${vmName}-NIC'
var labDeploymentScriptUri = 'https://raw.githubusercontent.com/cbattlegear/SqlServerMigrationTraining/master/InstallSqlServerLabDeployments.ps1'
var deploymentParameters = '-ComputerName "${vmName}" -UserAccountName "${administratorLogin}" -SqlServiceAccountName "sqlService" -SqlServiceAccountPassword "${administratorLoginPassword}"'


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow_tds_inbound'
        properties: {
          description: 'Allow access to data'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_redirect_inbound'
        properties: {
          description: 'Allow inbound redirect traffic to Managed Instance inside the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '11000-11999'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_all_inbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_all_outbound'
        properties: {
          description: 'Deny all other outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource routeTable 'Microsoft.Network/routeTables@2021-08-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: sqlMiSubnetName
        properties: {
          addressPrefix: sqlMiSubnetPrefix
          routeTable: {
            id: routeTable.id
          }
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          delegations: [
            {
              name: 'managedInstanceDelegation'
              properties: {
                serviceName: 'Microsoft.Sql/managedInstances'
              }
            }
          ]
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetIpPrefix
        }
      }
      {
        name: vmSubnetName
        properties: {
          addressPrefix: vmSubnetPrefix
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: bastionPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: bastionHostName
  location: location
  dependsOn: [
    virtualNetwork
    publicIp
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, bastionSubnetName)
          }
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', bastionPublicIpAddressName)
          }
        }
      }
    ]
  }
}

resource managedInstance 'Microsoft.Sql/managedInstances@2021-11-01-preview' = {
  name: managedInstanceName
  location: location
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    virtualNetwork
  ]
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, sqlMiSubnetName)
    storageSizeInGB: storageSizeInGB
    vCores: vCores
    licenseType: licenseType
  }
}

resource sqlServer 'Microsoft.Sql/servers@2021-08-01-preview' = {
  name: sqlDBServerName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sqlServer
  name: sqlDBDatabaseName
  location: location
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    capacity: 2
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, vmSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource labVm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: administratorLogin
      adminPassword: administratorLoginPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource labVm_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: labVm
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.8'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        labDeploymentScriptUri
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File InstallSqlServerLabDeployments.ps1 ${deploymentParameters}'
    }
  }
}

resource sa 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}
