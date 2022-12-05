@secure()
param kubeConfig string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource certManagerClusterIssuer 'cert-manager.io/ClusterIssuer@v1' = {
  metadata: {
    name: 'le-cluster-issuer'
  }
  spec: {
    acme: {
      server: 'https://acme-v02.api.letsencrypt.org/directory'
      email: 'maffemaandag@vxcompany.com'
      privateKeySecretRef: {
        name: 'letsencrypt-prod'
      }
      solvers: [
        {
          dns01: {
            azureDNS: {
              subscriptionID: '6eaaf383-01c1-4431-921c-73577a49128d'
              resourceGroupName: 'dns'
              hostedZoneName: 'maffe-maandag.nl'
              environment: 'AzurePublicCloud'
              managedIdentity: {
                clientID: '17214075-3150-4414-8a30-59c55bb4168d'
              }
            }
          }
        }
      ]
    }
  }
}
