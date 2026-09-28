// Example call for the CyberArk connector tier, matching Build Parameters v3.2.
// Production shown; dev is identical with dev in the names and its own subnet addresses.

param location string = 'centralus'
param subnetId string
param tags object = {}

module internalLoadBalancer 'br:gehabicep.azurecr.io/bicep/modules/loadbalancer:v1.1.0' = {
  name: 'lbi-cyberark'
  params: {
    location: location
    tags: tags
    lbDetails: {
      name: 'lbi-sec-cyberark-cus-prd-01'
      subnetId: subnetId
      privateIPAddress: '<fourth usable address of the subnet>'
      frontendZones: ['1', '2', '3']

      // Build Parameters v3.2: five tuple hash, no session persistence, idle 1200 seconds
      loadDistribution: 'Default'
      idleTimeoutInMinutes: 20
      enableTcpReset: true

      // Build Parameters v3.2: two probes, 30 second interval, unhealthy threshold 3
      probes: [
        {
          name: 'probe-tcp-3389'
          protocol: 'Tcp'
          port: 3389
          intervalInSeconds: 30
          probeThreshold: 3
        }
        {
          name: 'probe-https-health'
          protocol: 'Https'
          port: 443
          requestPath: '/psm/api/health'
          intervalInSeconds: 30
          probeThreshold: 3
        }
      ]

      rules: [
        {
          name: 'rule-tcp-3389'
          port: 3389
          probeName: 'probe-tcp-3389'
        }
      ]
    }
  }
}

output loadBalancerId string = internalLoadBalancer.outputs.loadBalancerId
output backendAddressPoolId string = internalLoadBalancer.outputs.backendAddressPoolId
