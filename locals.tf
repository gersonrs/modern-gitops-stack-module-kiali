locals {
  domain = "${var.subdomain != "" ? "${trimprefix(var.subdomain, ".")}." : ""}${var.base_domain}"

  helm_values = [{
    httproute = {
      enabled           = true
      host              = "kiali.${local.domain}"
      gateway_name      = var.gateway_name
      gateway_namespace = var.gateway_namespace
    }
    kiali-operator = {
      cr = {
        create = true
        namespace : var.namespace
        annotations : {}
        spec = {
          auth = {
            strategy = "openid"
            openid = {
              client_id  = var.oidc.client_id
              issuer_uri = var.oidc.issuer_url
              # No OIDC integration with the Kubernetes API server, so RBAC-based
              # namespace access control is disabled; all users share cluster-wide access.
              disable_rbac             = true
              username_claim           = "email"
              scopes                   = ["openid", "profile", "email"]
              insecure_skip_verify_tls = var.cluster_issuer != "letsencrypt-prod"
            }
          }
          deployment = {
            cluster_wide_access = true
            view_only_mode      = false
          }
          server = {
            web_root   = "/kiali"
            web_fqdn   = "kiali.${local.domain}"
            web_schema = "https"
            # The Istio gateway does not forward X-Forwarded-Port, so Kiali
            # cannot guess the ingress port and falls back to its internal
            # server port (20001), producing invalid redirect URLs. Pin the
            # external ingress port explicitly.
            web_port = "443"
          }
          external_services = {
            prometheus = {
              url = "http://kube-prometheus-stack-prometheus.kube-prometheus-stack.svc.cluster.local:9090/"
            }
            grafana = {
              enabled      = true
              internal_url = "http://kube-prometheus-stack-grafana.kube-prometheus-stack.svc.cluster.local:80/"
              external_url = "https://grafana.${local.domain}/"
              auth = {
                type     = "basic"
                username = "secret:kube-prometheus-stack-grafana:admin-user"
                password = "secret:kube-prometheus-stack-grafana:admin-password"
              }
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
