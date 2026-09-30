// Deployed at subscription scope so the target subscription and resource group
// come from the .bicepparam file instead of the pipeline's az context.
targetScope = 'subscription'

@description('Timestamp used to make the module deployment name unique.')
param deploymentTimeStamp string = utcNow('yyyyMMddHHmmss')

@description('Environment name, e.g. dev or prd.')
param env string

@description('Subscription ID the load balancer is deployed into.')
param subscriptionId string

@description('Resource group the load balancer is deployed into (must already exist).')
param resourceGroupName string

@description('Azure region for the load balancer.')
param location string

@description('Load balancer type.')
@allowed([
  'Internal'
  'External'
])
param lbType string = 'Internal'

@description('Full load balancer configuration (name, subnetId, privateIPAddress, probe, rules).')
param lbDetails object

@description('Extra tags merged with the standard tags.')
param tags object = {}

var standardTags = {
  Environment: env
  Application: 'CyberArk'
}

module loadbalancer 'br:gehabicep.azurecr.io/bicep/modules/loadbalancer:v1.0.0' = {
  name: 'lb-${deploymentTimeStamp}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    lbType: lbType
    tags: union(standardTags, tags)
    lbDetails: lbDetails
  }
}

output loadBalancerName string = loadbalancer.outputs.loadBalancerName
output loadBalancerId string = loadbalancer.outputs.loadBalancerId
output backendAddressPoolId string = loadbalancer.outputs.backendAddressPoolId
output frontendIp string = loadbalancer.outputs.frontendIp
