param location string = 'eastus2'
param registryName string = 'StableRegistry'
param clusterName string = 'StableCluster'
param k8sversion string = '1.25.6'
param nodeCount int = 2
param nodeSize string = 'Standard_E2bs_v5'
param nodeCountGPU int = 1
param nodeSizeGPU string = 'Standard_NC6s_v3'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-02-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: k8sversion
    dnsPrefix: clusterName
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
      loadBalancerSku: 'standard'
    }
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: nodeCount
        vmSize: nodeSize
        osType: 'Linux'
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        availabilityZones: []
        enableAutoScaling: false
        osDiskSizeGB: 30
        osDiskType: 'Managed'
      }
      {
        name: 'gpupool'
        count: nodeCountGPU
        vmSize: nodeSizeGPU
        osType: 'Linux'
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        availabilityZones: []
        enableAutoScaling: false
        osDiskSizeGB: 30
        osDiskType: 'Ephemeral'
      }
    ]
  }
}

resource registry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}
