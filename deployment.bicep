targetScope = 'resourceGroup'

@description('Timestamp used to make the module deployment name unique.')
param deploymentTimeStamp string = utcNow('yyyyMMddHHmmss')

@description('Environment name, e.g. dev or prd.')
param env string

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
