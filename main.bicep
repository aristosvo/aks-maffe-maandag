@description('The name of the Managed Cluster resource.')
param clusterName string = 'aks-maffe-maandag'

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The number of nodes for the cluster.')
@minValue(1)
@maxValue(50)
param agentCount int = 1

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_D2s_v3'

// @description('User name for the Linux Virtual Machines.')
// param linuxAdminUsername string

// @description('Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
// param sshRSAPublicKey string

@description('The base URI where artifacts required by this template are located')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access artifacts')
@secure()
param _artifactsLocationSasToken string = ''

@description('Public Helm Repo Name')
param helmRepo string = 'azure-marketplace'

@description('Public Helm Repo URL')
param helmRepoURL string = 'https://marketplace.azurecr.io/helm/v1/repo'

@description('Public Helm App')
param helmApp string = 'azure-marketplace/wordpress'

@description('Public Helm App Name')
param helmAppName string = 'my-wordpress'

resource aksidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  location: location
  name: 'id-maffe-maandag'
}

resource aks 'Microsoft.ContainerService/managedClusters@2020-09-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksidentity.id}': {}
    }
  }

  properties: {
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
      }
    ]
    // linuxProfile: {
    //   adminUsername: linuxAdminUsername
    //   ssh: {
    //     publicKeys: [
    //       {
    //         keyData: sshRSAPublicKey
    //       }
    //     ]
    //   }
    // }
  }
}

@description('The name of our container registry')
param containerRegistryName string = 'acr-maffe-maandag'
resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: true
  }
}

var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aks.id, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

module dns 'modules/dns.bicep' = {
  name: 'dns'
  scope: resourceGroup('dns')
  params: {
    kubeletidentityObjectId: aks.properties.identityProfile.kubeletidentity.objectId
  }
}

module helm 'modules/helm.bicep' = {
  name: 'HelmScripts'
  params: {
    location: location
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    clusterName: clusterName
    helmRepo: helmRepo
    helmRepoURL: helmRepoURL
    helmApp: helmApp
    helmAppName: helmAppName
  }
}

output kubeletIdentityClientId string = aks.properties.identityProfile.kubeletidentity.clientId

output controlPlaneFQDN string = aks.properties.fqdn
