resource "null_resource" "dependencies" {
  triggers = var.dependency_ids
}

# Kiali's `secret:<name>:<key>` reference for external_services.grafana.auth
# mounts the referenced secret as a volume in the Kiali pod, which only works
# for secrets in Kiali's own namespace. Rather than reading the Grafana admin
# secret cross-namespace at plan time (which breaks on a fresh bootstrap since
# it wouldn't exist yet), the password is passed in directly as a variable and
# the secret is created locally. Grafana's admin username defaults to "admin".
resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "kube-prometheus-stack-grafana"
    namespace = var.namespace
  }

  data = {
    "admin-user"     = "admin"
    "admin-password" = var.grafana_admin_password
  }
}

data "utils_deep_merge_yaml" "values" {
  input = [for i in concat(local.helm_values, var.helm_values) : yamlencode(i)]
}

resource "argocd_project" "this" {
  count = var.argocd_project == null ? 1 : 0

  metadata {
    name      = var.destination_cluster != "in-cluster" ? "kiali-${var.destination_cluster}" : "kiali"
    namespace = var.argocd_namespace
    annotations = {
      "modern-gitops-stack.io/argocd_namespace" = var.argocd_namespace
    }
  }

  spec {
    description  = "kiali application project for cluster ${var.destination_cluster}"
    source_repos = [var.project_source_repo]


    destination {
      name      = var.destination_cluster
      namespace = var.namespace
    }

    orphaned_resources {
      warn = true
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

resource "argocd_application" "this" {
  metadata {
    name      = var.destination_cluster != "in-cluster" ? "kiali-${var.destination_cluster}" : "kiali"
    namespace = var.argocd_namespace
    labels = merge({
      "application" = "kiali"
      "cluster"     = var.destination_cluster
    }, var.argocd_labels)
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = var.argocd_project == null ? argocd_project.this[0].metadata.0.name : var.argocd_project

    source {
      repo_url        = var.project_source_repo
      path            = "charts/kiali-operator"
      target_revision = var.target_revision
      helm {
        values = data.utils_deep_merge_yaml.values.output
      }
    }

    destination {
      name      = var.destination_cluster
      namespace = var.namespace
    }

    sync_policy {
      dynamic "automated" {
        for_each = toset(var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? [] : [var.app_autosync])
        content {
          prune       = automated.value.prune
          self_heal   = automated.value.self_heal
          allow_empty = automated.value.allow_empty
        }
      }

      retry {
        backoff {
          duration     = "20s"
          max_duration = "2m"
          factor       = "2"
        }
        limit = "5"
      }

      sync_options = [
        "CreateNamespace=true",
      ]
    }
  }

  depends_on = [
    resource.null_resource.dependencies,
    resource.kubernetes_secret_v1.grafana_admin,
  ]
}

resource "null_resource" "this" {
  depends_on = [
    resource.argocd_application.this,
  ]
}
