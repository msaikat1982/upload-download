// PROPOSED MODULE for TIO/Azure.Bicep.Modules  ->  modules/loadbalancer/loadbalancer.bicep
// Publish tag: loadbalancer/v1.1.0
//
// Internal Standard load balancer: one static private front end, one backend pool,
// one or more health probes, and N load balancing rules.
//
// Changes against the v1.0.0 proposal, to match CyberArk PAS Azure Build Parameters v3.2:
//   1. Multiple health probes. v3.2 requires two - a transport check on TCP 3389 and a
//      service check against the session manager health endpoint on HTTPS 443.
//   2. Probe protocol is selectable (Tcp, Http, Https) with an optional requestPath,
//      which the health endpoint probe needs.
//   3. Each rule names the probe it uses, defaulting to the first probe.
//   4. loadDistribution now defaults to 'Default' - the platform five tuple hash with no
//      session persistence, per v3.2. It was 'SourceIP' in v1.0.0.
//   5. Idle timeout now defaults to 20 minutes, the 1200 seconds given in v3.2. It was 30.
//   6. Probe interval and threshold now default to 30 seconds and 3, per v3.2.
//
// The singular lbDetails.probe from v1.0.0 is still accepted, so existing callers keep working.
// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/loadbalancers?pivots=deployment-language-bicep

@description('Region for the load balancer.')
@allowed(['centralus', 'eastus', 'eastus2', 'northcentralus', 'southcentralus', 'westus'])
param location string

@description('Full configuration object for the internal load balancer.')
param lbDetails object

@description('Tags applied to the load balancer.')
param tags object = {}

var lbName = lbDetails.name
var feName = 'fe-${lbName}'
var poolName = 'bep-${lbName}'

// Accept either the v1.1.0 probes array or the v1.0.0 singular probe.
var probeList = lbDetails.?probes ?? [lbDetails.probe]

resource loadBalancer 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: lbName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: feName
        zones: lbDetails.?frontendZones ?? ['1', '2', '3']
        properties: {
          subnet: {
            id: lbDetails.subnetId
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: lbDetails.privateIPAddress
        }
      }
    ]
    backendAddressPools: [
      {
        name: poolName
      }
    ]
    probes: [
      for p in probeList: {
        name: p.name
        properties: union(
          {
            protocol: p.?protocol ?? 'Tcp'
            port: p.port
            intervalInSeconds: p.?intervalInSeconds ?? 30
            numberOfProbes: p.?probeThreshold ?? 3
            probeThreshold: p.?probeThreshold ?? 3
          },
          // requestPath is required for Http and Https probes and must be absent for Tcp
          contains(p, 'requestPath') ? { requestPath: p.requestPath } : {}
        )
      }
    ]
    loadBalancingRules: [
      for rule in lbDetails.rules: {
        name: rule.name
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, feName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, poolName)
          }
          probe: {
            id: resourceId(
              'Microsoft.Network/loadBalancers/probes',
              lbName,
              rule.?probeName ?? probeList[0].name
            )
          }
          protocol: rule.?protocol ?? 'Tcp'
          frontendPort: rule.port
          backendPort: rule.?backendPort ?? rule.port
          // 'Default' is the platform five tuple hash, which is no session persistence
          loadDistribution: lbDetails.?loadDistribution ?? 'Default'
          idleTimeoutInMinutes: lbDetails.?idleTimeoutInMinutes ?? 20
          enableTcpReset: lbDetails.?enableTcpReset ?? true
          enableFloatingIP: false
          disableOutboundSnat: true
        }
      }
    ]
  }
}

output loadBalancerName string = loadBalancer.name
output loadBalancerId string = loadBalancer.id
output backendAddressPoolId string = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, poolName)
output frontendPrivateIp string = lbDetails.privateIPAddress
