@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr-${uniqueString(resourceGroup().id)}'

@description('Provide a location for the registry.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
param acrSku string = 'Basic'

param resourceTags object = {
  Description: 'Azure Container Registry to store images'
   Environment: 'Demo'
   ResourceType: 'Containers'
}

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  tags: resourceTags
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
  }
}

module buildBasicAcrImage 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: 'buildAcrImage-basic'
  params: {
    AcrName: acrName
    location: location
    gitRepositoryUrl: 'https://github.com/vrhovnik/azure-demo-monitoring-basics.git'
    dockerfileDirectory: 'containers'
    imageName: 'basic'
    imageTag: 'latest'
    dockerfileName: 'Dockerfile-basic'    
  }
}

module buildGeneralAcrImage 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: 'buildAcrImage-general'
  params: {
    AcrName: acrName
    location: location
    gitRepositoryUrl: 'https://github.com/vrhovnik/azure-demo-monitoring-basics.git'    
    dockerfileDirectory: 'containers'
    imageName: 'general'
    imageTag: 'latest'
    dockerfileName: 'Dockerfile-general'    
  }
}

@description('Output the login server and registry name')
output loginServer string = acrResource.properties.loginServer
output loginName string = acrResource.name
