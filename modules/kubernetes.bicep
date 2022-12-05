@secure()
param kubeConfig string

import 'kubernetes@1.0.0' with {
  kubeConfig: kubeConfig
  namespace: 'default'
}

resource namespaceApps 'core/Namespace@v1' = {
  metadata: {
    name: 'apps'
  }
}

module shell './shell.bicep' = {
  name: 'kubernetes-deploy-shell'
  params: {
    kubeConfig: kubeConfig
    namespace: namespaceApps.metadata.name
  }
}

module welkom './welkom.bicep' = {
  name: 'kubernetes-deploy-welkom'
  params: {
    kubeConfig: kubeConfig
    namespace: namespaceApps.metadata.name
  }
}
