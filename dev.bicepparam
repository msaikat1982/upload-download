using 'deployment.bicep'

// ---- values used to build lbDetails ----
var lbName = 'cyberark-loadbalancer-dev'
var subnetId = '/subscriptions/e657afbe-61e4-4a5f-b6cb-cfbba50fd3a6/resourceGroups/rg-alz-centralus-vnet-cip-cus-dev-01/providers/Microsoft.Network/virtualNetworks/vnet-cip-cus-dev-01/subnets/snet-cip-dev-01'

// ---- parameters (each one must be declared in deployment.bicep) ----
param env = 'dev'
param location = 'centralus'
param lbType = 'Internal'
param tags = {}

param lbDetails = {
  name: lbName
  subnetId: subnetId
  privateIPAddress: '10.9.18.50'

  // Health probe (the module requires 'probe' or 'probes')
  probe: {
    name: 'probe-https-443'
    protocol: 'Tcp'
    port: 443
    intervalInSeconds: 15
    probeThreshold: 2
  }

  // Load-balancing rules (the module requires 'rules')
  rules: [
    {
      name: 'rule-https-443'
      protocol: 'Tcp'
      port: 443
      backendPort: 443
    }
  ]
}
