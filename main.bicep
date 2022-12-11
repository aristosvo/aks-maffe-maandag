@description('The location of all the resources.')
param location string = resourceGroup().location

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string

module aks 'modules/aks.bicep' = {
  name: 'aks-maffe-maandag'
  params: {
    dnsPrefix: dnsPrefix
    location: location
  }
}

module dns 'modules/dns.bicep' = {
  name: 'dns'
  scope: resourceGroup('dns')
  params: {
    kubeletidentityObjectId: aks.outputs.kubeletIdentityObjectId
  }
}

module ingress 'modules/helm.bicep' = {
  name: 'ingress'
  params: {
    useExistingManagedIdentity: true
    managedIdentityName: aks.outputs.runManagedIdentityName
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
    managedIdentityName: aks.outputs.runManagedIdentityName
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

module externalDNS 'modules/helm.bicep' = {
  name: 'external-dns'
  params: {
    useExistingManagedIdentity: true
    managedIdentityName: aks.outputs.runManagedIdentityName
    aksName: aks.name
    location: location
    helmRepo: 'bitnami'
    helmRepoURL: 'https://charts.bitnami.com/bitnami'
    helmApps: [
      {
        helmAppName: 'external-dns'
        helmApp: 'bitnami/external-dns'
        helmAppParams: '--version 6.12.1 --namespace external-dns --create-namespace --set provider=azure --set azure.resourceGroup=dns --set azure.tenantId=${subscription().tenantId} --set azure.subscriptionId=${subscription().subscriptionId} --set azure.useManagedIdentityExtension=true'
      }
    ]
  }
}
// 

// module kubernetes './modules/kubernetes.bicep' = {
//   name: 'kubernetes-deploy'
//   params: {
//     kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
//   }
// }

output certmanagerOutput array = certmanager.outputs.helmOutputs

output ingressOutput array = ingress.outputs.helmOutputs

output kubeletIdentityClientId string = aks.outputs.kubeletIdentityClientId

output controlPlaneFQDN string = aks.outputs.controlPlaneFQDN
