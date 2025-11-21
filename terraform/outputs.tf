output "cluster_name" {
  description = "Name of the Minikube cluster"
  value       = "${var.cluster_name}-${var.environment}"
}

output "kubernetes_version" {
  description = "Kubernetes version"
  value       = var.kubernetes_version
}

output "namespace" {
  description = "Application namespace"
  value       = var.namespace
}

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "cluster_endpoint" {
  description = "Cluster endpoint URL"
  value       = "Run: minikube ip -p ${var.cluster_name}-${var.environment}"
}

output "ingress_urls" {
  description = "Application URLs"
  value = {
    vote   = "http://vote.local"
    result = "http://result.local"
  }
}

output "resource_config" {
  description = "Resource configuration for this environment"
  value = {
    replicas     = var.app_replicas[var.environment]
    storage_size = var.db_storage_size[var.environment]
    cpu_limit    = var.resource_limits[var.environment].cpu
    memory_limit = var.resource_limits[var.environment].memory
  }
}

output "next_steps" {
  description = "Next steps to deploy the application"
  value       = <<-EOT
    
    1. Set kubectl context:
       kubectl config use-context ${var.cluster_name}-${var.environment}
    
    2. Verify cluster:
       kubectl cluster-info
       kubectl get nodes
    
    3. Deploy databases via Helm:
       helm repo add bitnami https://charts.bitnami.com/bitnami
       helm install postgresql bitnami/postgresql -n ${var.namespace} -f ../k8s/helm/postgresql-values-${var.environment}.yaml
       helm install redis bitnami/redis -n ${var.namespace} -f ../k8s/helm/redis-values-${var.environment}.yaml
    
    4. Deploy application via Helm:
       helm install voting-app ../k8s/helm/voting-app -n ${var.namespace} --set environment=${var.environment}
    
    5. Access the application:
       Vote:   http://vote.local
       Result: http://result.local
  EOT
}
