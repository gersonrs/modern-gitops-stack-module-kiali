locals {
  domain = var.base_domain != "" ? "${var.subdomain != "" ? "${trimprefix(var.subdomain, ".")}." : ""}${var.base_domain}" : ""

  helm_values = [{
    kiali-operator = {
      cr = {
        create = true
        namespace : var.namespace
        annotations : {}
        spec = {
          auth = {
            strategy = "anonymous"
          }
          deployment = {
            cluster_wide_access = true
            view_only_mode      = false
          }
          server = {
            web_root = "/kiali"
          }
          external_services = {
            prometheus = {
              url = "http://kube-prometheus-stack-prometheus.kube-prometheus-stack.svc.cluster.local:9090/"
            }
            grafana = {
              enabled      = true
              internal_url = "http://kube-prometheus-stack-grafana.kube-prometheus-stack.svc.cluster.local:80/"
              external_url = "https://grafana.${local.domain}/"
              dashboards = [
                {
                  name = "Istio Service Dashboard"
                  variables = {
                    namespace = var.namespace
                    service   = "var-service"
                  }
                },
                {
                  name = "Istio Workload Dashboard"
                  variables = {
                    namespace = var.namespace
                    workload  = "var-workload"
                  }
                },
                {
                  name = "Istio Mesh Dashboard"
                },
                {
                  name = "Istio Control Plane Dashboard"
                },
                {
                  name = "Istio Performance Dashboard"
                },
                {
                  name = "Istio Wasm Extension Dashboard"
                }
              ]
            }
          }
        }
      }
    }
  }]
}
