@secure()
param kubeConfig string

param namespace string

import 'kubernetes@1.0.0' with {
  namespace: namespace
  kubeConfig: kubeConfig
}

resource appsDeployment_shell 'apps/Deployment@v1' = {
  metadata: {
    name: 'shell'
  }
  spec: {
    selector: {
      matchLabels: {
        app: 'shell'
      }
    }
    replicas: 1
    template: {
      metadata: {
        labels: {
          app: 'shell'
        }
      }
      spec: {
        containers: [
          {
            name: 'shell'
            image: 'albertstarreveld/mm-shell'
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

resource coreService_shellService 'core/Service@v1' = {
  metadata: {
    name: 'shell-service'
  }
  spec: {
    selector: {
      app: 'shell'
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

resource networkingK8sIoIngress_shellIngressRules 'networking.k8s.io/Ingress@v1' = {
  metadata: {
    name: 'shell-ingress-rules'
    annotations: {
      'cert-manager.io/cluster-issuer': 'le-cluster-issuer'
      'nginx.ingress.kubernetes.io/rewrite-target': '/'
    }
  }
  spec: {
    ingressClassName: 'ingress-nginx'
    rules: [
      {
        host: 'maffe-maandag.nl'
        http: {
          paths: [
            {
              path: '/?(.*)'
              pathType: 'Prefix'
              backend: {
                service: {
                  name: 'shell-service'
                  port: {
                    number: 80
                  }
                }
              }
            }
          ]
        }
      }
      {
        host: 'www.maffe-maandag.nl'
        http: {
          paths: [
            {
              path: '/?(.*)'
              pathType: 'Prefix'
              backend: {
                service: {
                  name: 'shell-service'
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
          'www.maffe-maandag.nl'
          'maffe-maandag.nl'
        ]
        secretName: 'shell-cert'
      }
    ]
  }
}
