@description('Location for all resources.')
param location string = resourceGroup().location

@description('Enter SQL Migration Lab VM Name.')
param vmName string

@description('Default VM Size')
param vmSize string = 'Standard_E8s_v4'

@description('Enter user name, this will be your VM Login, SQL DB Admin, and SQL MI Admin')
param administratorLogin string

@description('Enter password, this will be your VM Password, SQL DB Admin Password, SQL MI Admin Password, and sa Password')
@secure()
param administratorLoginPassword string

@description('Enter virtual network name. If you leave this field blank name will be created by the template.')
param virtualNetworkName string = 'SQLMigrationLab-vNet'

@description('Enter Managed Instance subnet name.')
param vmSubnetName string = 'VMSubnet'

var nicName = '${vmName}-NIC'
var labDeploymentScriptUri = 'https://raw.githubusercontent.com/cbattlegear/SqlServerMigrationTraining/master/InstallSqlServerLabDeployments.ps1'
var deploymentParameters = '-ComputerName "${vmName}" -UserAccountName "${administratorLogin}" -SqlServiceAccountName "sqlService" -SqlServiceAccountPassword "${administratorLoginPassword}"'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: virtualNetworkName
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
