output "id" {
  description = "ID to pass other modules in order to refer to this module as a dependency."
  value       = resource.null_resource.this.id
}

output "gateway_name" {
  description = "Name of the Istio Gateway resource for use in HTTPRoute parentRefs."
  value       = "istio-gateway"
}

output "gateway_namespace" {
  description = "Namespace of the Istio Gateway resource for use in HTTPRoute parentRefs."
  value       = "istio-ingress"
}
