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

@description('An array of Azure RoleIds that are required for the DeploymentScript resource')
param rbacRolesNeeded array = [
  'b24988ac-6180-42a0-ab88-20f7382dd24c' //Contributor
  '7f6c6a51-bcf8-42ba-9220-52d62157d7db' //Azure Kubernetes Service RBAC Reader
]

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
  }
}

@description('The name of our container registry')
param containerRegistryName string = 'maffemaandag'
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

resource aksrunid 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'id-run-maffe-maandag'
  location: location
}

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefId in rbacRolesNeeded: {
  name: guid(aks.id, roleDefId, aksrunid.id)
  scope: aks
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefId)
    principalId: aksrunid.properties.principalId
    principalType: 'ServicePrincipal'
  }
}]

module ingress 'modules/helm.bicep' = {
  name: 'ingress'
  params: {
    useExistingManagedIdentity: true
    managedIdentityName: aksrunid.name
    aksName: aks.name
    location: location
    helmRepo: 'ingress-nginx'
    helmRepoURL: 'https://kubernetes.github.io/ingress-nginx'
    helmApps: [
      {
        helmAppName: 'ingress-nginx'
        helmApp: 'ingress-nginx/ingress-nginx'
        helmAppParams: '--version 4.4.0 --namespace ingress --create-namespace --set controller.service.externalTrafficPolicy=Local'
      }
    ]
  }
}

module certmanager 'modules/helm.bicep' = {
  name: 'certmanager'
  params: {
    useExistingManagedIdentity: true
    managedIdentityName: aksrunid.name
    aksName: aks.name
    location: location
    helmRepo: 'jetstack'
    helmRepoURL: 'https://charts.jetstack.io'
    helmApps: [
      {
        helmAppName: 'cert-manager'
        helmApp: 'jetstack/cert-manager'
        helmAppParams: '--version v1.10.1 --namespace cert-manager --create-namespace --set installCRDs=true'
      }
    ]
  }
}

output certmanagerOutput array = certmanager.outputs.helmOutputs

output ingressOutput array = ingress.outputs.helmOutputs

output kubeletIdentityClientId string = aks.properties.identityProfile.kubeletidentity.clientId

output controlPlaneFQDN string = aks.properties.fqdn
