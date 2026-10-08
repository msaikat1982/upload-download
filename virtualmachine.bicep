// https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines?pivots=deployment-language-bicep#virtualmachineidentity

@description('A timestamp for naming unique deployments.')
param deploymentTimeStamp string = utcNow('yyyyMMddHHmmss')

@description('Specifies the region in which the virtual machine will be created.')
@allowed(['centralus','eastus','northcentralus','southcentralus', 'westus'])
param location string

@description('Full object containing all configuration details for the virtual machine. This object is used to populate other parameters.')
param vmDetails object

@description('Specifies the name of the virtual machine.')
param vmName string = vmDetails.vmName

@description('Specifies the availability zones in which the virtual machine will be deployed.')
param zones array = vmDetails.zones

@description('Specifies the type of managed identity assigned to the virtual machine.')
@allowed([
  'SystemAssigned'
  'UserAssigned'
  'None'
])
param identity string = vmDetails.identity.type

@description('Specifies the size of the virtual machine.')
param vmSize string = vmDetails.properties.hardwareProfile.vmSize

@description('Indicates whether hibernation is enabled for the virtual machine.')
param hibernationEnabled bool = vmDetails.properties.additionalCapabilities.hibernationEnabled

@allowed([
  'cis2025'
  'ubuntu2404'
])
param operatingSystem string = vmDetails.properties.storageProfile.imageReference

var imageReferenceMap = {
  cis2025: {
      imageReference: {
          publisher: 'center-for-internet-security-inc'
          offer: 'cis-windows-server'
          sku: 'cis-windows-server2025-l1-gen2'
          version: 'latest'
      }
      plan: {
          publisher: 'center-for-internet-security-inc'
          product: 'cis-windows-server'
          name: 'cis-windows-server2025-l1-gen2'
      }
  }
  ubuntu2404: {
      imageReference: {
          publisher: 'Canonical'
          offer: 'ubuntu-24_04-lts'
          sku: 'server'
          version: 'latest'
      }
      plan: null
  }
}

var osConfiguration = vmDetails.properties.storageProfile.osDisk.osType == 'Linux' 
  ? {
    linuxConfiguration: {
      disablePasswordAuthentication: false
      provisionVMAgent: true
      patchSettings: {
        patchMode: 'ImageDefault'
        assessmentMode: 'ImageDefault'
      }
    }
    } : {
    windowsConfiguration: {
      provisionVMAgent: true
      enableAutomaticUpdates: false
      patchSettings: {
        patchMode: 'Manual'
        assessmentMode: 'ImageDefault'
      }
    }
  }
    
@description('Specifies the operating system type for the OS disk.')
@allowed([
  'Linux'
  'Windows'
])
param osType string = vmDetails.properties.storageProfile.osDisk.osType

@description('Specifies how the OS disk is created.')
@allowed([
  'FromImage'
  'Attach'
])
param createOption string = 'FromImage'

@description('Specifies the caching mode for the OS disk.')
@allowed([
  'ReadWrite'
  'ReadOnly'
  'None'
])
param caching string = 'None'

@description('Specifies the storage account type for the managed disk.')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param storageAccountType string = vmDetails.properties.storageProfile.osDisk.managedDisk.storageAccountType

@description('Specifies the behavior when the virtual machine is deleted.')
@allowed([
  'Delete'
  'Detach'
])
param deleteOption string = vmDetails.properties.storageProfile.osDisk.deleteOption

@description('Specifies the size of the OS disk in gigabytes.')
param diskSizeGB int = vmDetails.properties.storageProfile.osDisk.diskSizeGB

@description('Specifies the data disks attached to the virtual machine, if any.')
param dataDisks array = vmDetails.properties.storageProfile.dataDisks

@description('Specifies the disk controller type used for the virtual machine.')
@allowed([
  'SCSI'
  'NVMe'
])
param diskControllerType string = 'SCSI'

param adminUserName string = 'azureuser'
@secure()
param adminPassword string

resource virtualMachine 'Microsoft.Compute/virtualMachines@2025-11-01' = {
  name: vmName
  location: location
  zones: zones
  identity: {
    type: identity
  }
  plan: imageReferenceMap[operatingSystem].plan
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    additionalCapabilities: {
      hibernationEnabled: hibernationEnabled
    }
    storageProfile: {
      imageReference: imageReferenceMap[operatingSystem].imageReference
      osDisk: {
        osType: osType
        name: '${vmName}-osdisk'
        createOption: createOption
        caching: caching
        managedDisk: {
          storageAccountType: storageAccountType
        }
        deleteOption: deleteOption
        diskSizeGB: diskSizeGB
      }
      dataDisks: dataDisks
      diskControllerType: diskControllerType
    }
    osProfile: union(
    {
      computerName: vmDetails.vmName
      adminUsername: adminUserName
      adminPassword: adminPassword
      secrets: []
      allowExtensionOperations: true
      //requireGuestProvisionSignal: true
    }, osConfiguration)
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

output virtualMachineName string = virtualMachine.name
output virtualMachineId string = virtualMachine.id

param ipconfigName string = 'ipconfig1'
param privateIPAllocationMethod string = 'Dynamic'

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${vmDetails.vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: ipconfigName
        properties: {
          privateIPAllocationMethod: privateIPAllocationMethod
          subnet: { 
            id: vmDetails.subnetId 
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: [
        '10.100.10.10'
        '10.100.10.12'
        '10.100.10.8'
        '10.100.10.9'
        '10.110.10.10'
        '10.110.10.12'
        '168.63.129.16'
      ]
    }
  }
}

var privateIp = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

param dnsZoneName string = 'azurevm.geha.com'
param dnsZoneResourceGroup string = 'rg-tio-dns-southcentralus-01'
param dnsZoneSubscriptionId string = 'f0bacc2a-12d2-4cd5-86f8-80d5a18fa89e'

module dnsecord 'br:gehabicep.azurecr.io/bicep/modules/dnsrecord:v1.0.0' = {
  name: 'dnsrecord-${deploymentTimeStamp}'
  scope: resourceGroup(dnsZoneSubscriptionId, dnsZoneResourceGroup)
  params: {
    dnsZoneName: dnsZoneName
    name: virtualMachine.name
    privateIp: privateIp
  }
}

// currently unused parameters...

// @description('Indicates whether password authentication should be disabled for the Linux VM. Set to true to enforce SSH key-only access.')
// param disablePasswordAuthentication bool = vmDetails.properties.osProfile.linuxConfiguration.disablePasswordAuthentication

// @description('Indicates whether the Azure VM Agent should be provisioned on the Linux VM. Required for extensions and VM management features.')
// param provisionVMAgent bool = vmDetails.properties.osProfile.linuxConfiguration.provisionVMAgent

// @description('Specifies the patch mode for automatic OS updates on the Linux VM.')
// @allowed([
//   'ImageDefault'   // Uses the OS image default patching behavior
//   'Manual'         // No automatic updates
//   'AutomaticByPlatform'  // Platform-managed automatic updates
//   'AutomaticByOS'  // OS-managed automatic updates
// ])
// param patchMode string = vmDetails.properties.osProfile.linuxConfiguration.patchSettings.patchMode

// @description('Specifies the assessment mode for OS patch compliance on the Linux VM.')
// @allowed([
//   'ImageDefault'   // Uses the OS image default assessment mode
//   'AutomaticByPlatform'  // Platform-managed assessment
//   'AutomaticByOS'   // OS-managed assessment
// ])
// param assessmentMode string = vmDetails.properties.osProfile.linuxConfiguration.patchSettings.assessmentMode
