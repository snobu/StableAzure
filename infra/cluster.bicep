param location string = 'eastus'
param clusterName string = 'myAKSCluster'
param nodeCount int = 2
param nodeSize string = 'Standard_E2bs_v5'
param nodeCountGPU int = 1
param nodeSizeGPU string = 'Standard_NC6s_v3'
param registryName string = 'StableRegistry'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${clusterName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
    subnets: [
      {
        name: '${clusterName}-subnet'
        properties: {
          addressPrefix: '10.240.0.0/16'
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
              locations: [
                location
              ]
            }
          ]
          delegation: {
            name: '${clusterName}-delegation'
            properties: {
              serviceName: 'Microsoft.ContainerInstance/containerGroups'
              actions: [
                '*'
              ]
            }
          }
        }
      }
    ]
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-02-01' = {
  name: clusterName
  location: location
  properties: {
    kubernetesVersion: '1.22.10'
    dnsPrefix: clusterName
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
      loadBalancerSku: 'standard'
      networkPolicyProfile:{
        enabled:true
        networkPolicy:'azure'
      }
    }
    agentPoolProfiles:[
      {
        name:'systempool',
        count:${nodeCount},
        vmSize:'${nodeSize}',
        osType:'Linux',
        vnetSubnetId:virtualNetwork.subnets[0].id,
        maxPodsPerNode : 110,
        type:'VirtualMachineScaleSets',
        mode:'System',
        availabilityZones:[
          "1",
          "2",
          "3"
        ],
        enableAutoScaling:false,
        osDiskSizeGB : 30,
        osDiskType : "Ephemeral",
        storageProfile:{
          osDisk:{
            caching:"ReadWrite",
            managedDisk:{
              storageAccountType:"Premium_LRS"
            },
            diskSizeGB :30,
            diffDiskSettings:{
              option:"Local"
            }
          },
          imageReference:{
            offer:"UbuntuServer",
            publisher:"Canonical",
            sku:"20_04-lts-gen2",
            version:"latest"
          },
          dataDisks:[]
        }
      },
      {
        name:'userpool',
        count:${nodeCountGPU},
        vmSize:'${nodeSizeGPU}',
        osType:'Linux',
        vnetSubnetId:virtualNetwork.subnets[0].id,
        maxPodsPerNode : 110,
        type:'VirtualMachineScaleSets',
        mode:'User',
        availabilityZones:[
          "1",
          "2",
          "3"
        ],
        enableAutoScaling:false,
        osDiskSizeGB : 30,
        osDiskType : "Ephemeral",
        storageProfile:{
          osDisk:{
            caching
            : 'ReadWrite'
            managedDisk: {
              storageAccountType: 'Premium_LRS'
            }
            diskSizeGB :30,
            diffDiskSettings:{
              option:"Local"
            }
          },
          imageReference:{
            offer:"UbuntuServer",
            publisher:"Canonical",
            sku:"20_04-lts-gen2",
            version:"latest"
          },
          dataDisks:[]
        }
      }
    ]
    servicePrincipalProfile: {
      clientId: '<your-client-id>'
      secret: '<your-client-secret>'
    }
    addonProfiles: {
      aciConnectorLinux: {
        enabled: true
        config: {
          aciConnectorLinuxEnabled: true
        }
      }
    }
    identity:{
      type:'SystemAssigned'
    }
  }
}

resource registry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: registryName
  location: location
  properties:{
    adminUserEnabled:false
    sku:{
      name:'Standard'
    }
  }
}

resource aksRegistry 'Microsoft.ContainerService/managedClusters/providers/roleAssignments@2021-04-01-preview' = {
  name:'${aksCluster.id}/Microsoft.Authorization/roleAssignments/${guid()}'
  properties:{
    roleDefinitionId:'/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalId:registry.id
    scope:'${aksCluster.id}'
  }
}
