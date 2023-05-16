@description('Location for all resources.')
param location string = resourceGroup().location

@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param registryName string = 'acr-${uniqueString(resourceGroup().id)}'

@minLength(2)
@maxLength(64)
@description('Provide a globally unique name of your cluster name')
param clusterName string = 'stable-cluster-${uniqueString(resourceGroup().id)}'
param k8sversion string = '1.25.6'

@description('Provide a system node count for the cluster')
param nodeCount int = 2

@description('Provide a system node size for the cluster')
param nodeSize string = 'Standard_E2bs_v5'

@description('Provide a GPU node count for the cluster')
param nodeCountGPU int = 1

@description('Provide a GPU node size for the cluster')
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
