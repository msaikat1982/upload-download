// CyberArk PAS - production virtual machines
// Deploys cyberark-prd101 and cyberark-prd102 into separate availability zones
// using the shared generic virtualmachine module from the TIO registry.
//
// Deploy with:
//   az deployment sub create --subscription 87c9e9d1-06a7-4b33-87e0-5f04bcbfbfae \
//     --location centralus --template-file Virtualmachine.new.bicep \
//     --parameters adminPassword=$(VM_ADMIN_PASSWORD)

targetScope = 'subscription'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
@description('One VM to create and the availability zone it goes into.')
type vmInstance = {
  @description('VM name. Windows computer names are limited to 15 characters.')
  @maxLength(15)
  name: string

  @description('Availability zone for this VM.')
  zone: '1' | '2' | '3'
}

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
@description('Timestamp used to make nested deployment names unique.')
param deploymentTimeStamp string = utcNow('yyyyMMddHHmmss')

@description('Environment name.')
param env string = 'prd'

@description('Azure region for the VMs.')
param location string = 'centralus'

@description('Subscription the VMs are deployed into.')
param subscriptionId string = '87c9e9d1-06a7-4b33-87e0-5f04bcbfbfae'

@description('Resource group the VMs are deployed into (must already exist).')
param resourceGroupName string = 'rg-sec-cyberark-prd'

@description('Subscription that holds the VNet (same as the VM subscription by default).')
param vnetSubscriptionId string = subscriptionId

@description('Resource group that holds the VNet.')
param vnetResourceGroupName string = 'alz-centralus-vnet-cip-cus-prd-01'

@description('VNet name.')
param vnetName string = 'cip-cus-prd-01'

@description('Subnet name the VM NICs are attached to.')
param subnetName string = 'snet-sec-cyberark-cus-prd-01'

@description('VMs to create. Give each VM a different zone.')
@minLength(1)
param virtualMachines vmInstance[] = [
  {
    name: 'cyberark-prd101'
    zone: '1'
  }
  {
    name: 'cyberark-prd102'
    zone: '2'
  }
]

@description('VM size.')
param vmSize string = 'Standard_D2s_v7'

@description('OS image key understood by the virtualmachine module.')
@allowed([
  'cis2025'
  'ubuntu2404'
])
param operatingSystem string = 'cis2025'

@description('OS type.')
@allowed([
  'Windows'
  'Linux'
])
param osType string = 'Windows'

@description('OS disk size in GB.')
param osDiskSizeGB int = 127

@description('OS disk storage type.')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param osDiskStorageAccountType string = 'StandardSSD_LRS'

@description('Disk controller type. v6/v7 VM sizes need NVMe.')
@allowed([
  'SCSI'
  'NVMe'
])
param diskControllerType string = 'NVMe'

@description('Data disks to attach to each VM.')
param dataDisks array = []

@description('Managed identity type.')
@allowed([
  'SystemAssigned'
  'UserAssigned'
  'None'
])
param identityType string = 'SystemAssigned'

@description('Local administrator user name.')
param adminUserName string = 'azureuser'

@description('Local administrator password. Pass it from a secret pipeline variable or Key Vault.')
@secure()
param adminPassword string

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------
var subnetId = resourceId(
  vnetSubscriptionId,
  vnetResourceGroupName,
  'Microsoft.Network/virtualNetworks/subnets',
  vnetName,
  subnetName
)

// ---------------------------------------------------------------------------
// Virtual machines (one module instance per VM)
// ---------------------------------------------------------------------------
module vm 'br:gehabicep.azurecr.io/bicep/modules/virtualmachine:v1.0.0' = [
  for (item, i) in virtualMachines: {
    name: 'vm-${item.name}-${deploymentTimeStamp}'
    scope: resourceGroup(subscriptionId, resourceGroupName)
    params: {
      location: location
      // Unique per VM so the module's nested DNS record deployments don't clash
      deploymentTimeStamp: '${deploymentTimeStamp}-${item.name}'
      adminUserName: adminUserName
      adminPassword: adminPassword
      diskControllerType: diskControllerType
      vmDetails: {
        vmName: item.name
        zones: [
          item.zone
        ]
        subnetId: subnetId
        identity: {
          type: identityType
        }
        properties: {
          hardwareProfile: {
            vmSize: vmSize
          }
          additionalCapabilities: {
            hibernationEnabled: false
          }
          storageProfile: {
            imageReference: operatingSystem
            osDisk: {
              osType: osType
              managedDisk: {
                storageAccountType: osDiskStorageAccountType
              }
              deleteOption: 'Delete'
              diskSizeGB: osDiskSizeGB
            }
            dataDisks: dataDisks
          }
        }
      }
    }
  }
]

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output environment string = env
output subnetId string = subnetId
output virtualMachines array = [
  for (item, i) in virtualMachines: {
    name: vm[i].outputs.virtualMachineName
    id: vm[i].outputs.virtualMachineId
    zone: item.zone
  }
]
