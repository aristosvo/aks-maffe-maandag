@secure()
param kubeConfig string

param namespace string

import 'kubernetes@1.0.0' with {
  namespace: namespace
  kubeConfig: kubeConfig
}

resource appsDeployment_welkom 'apps/Deployment@v1' = {
  metadata: {
    name: 'welkom'
  }
  spec: {
    selector: {
      matchLabels: {
        app: 'welkom'
      }
    }
    replicas: 1
    template: {
      metadata: {
        labels: {
          app: 'welkom'
        }
      }
      spec: {
        containers: [
          {
            name: 'welkom'
            image: 'albertstarreveld/mm-welkom'
            ports: [
              {
                name: 'http-port'
                containerPort: 80
              }
            ]
          }
        ]
      }
    }
  }
}

resource coreService_welkomService 'core/Service@v1' = {
  metadata: {
    name: 'welkom-service'
  }
  spec: {
    selector: {
      app: 'welkom'
    }
    ports: [
      {
        name: 'http-port'
        port: 80
        targetPort: 'http-port'
        protocol: 'TCP'
      }
    ]
  }
}

resource networkingK8sIoIngress_welkomIngressRules 'networking.k8s.io/Ingress@v1' = {
  metadata: {
    name: 'welkom-ingress-rules'
    annotations: {
      'cert-manager.io/cluster-issuer': 'le-cluster-issuer'
      'nginx.ingress.kubernetes.io/rewrite-target': '/'
    }
  }
  spec: {
    ingressClassName: 'ingress-nginx'
    rules: [
      {
        host: 'welkom.maffe-maandag.nl'
        http: {
          paths: [
            {
              path: '/?(.*)'
              pathType: 'Prefix'
              backend: {
                service: {
                  name: 'welkom-service'
                  port: {
                    number: 80
                  }
                }
              }
            }
          ]
        }
      }
    ]
    tls: [
      {
        hosts: [
          'welkom.maffe-maandag.nl'
        ]
        secretName: 'welkom-cert'
      }
    ]
  }
}
