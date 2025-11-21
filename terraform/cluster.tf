# Minikube Cluster Provisioning
# This uses null_resource as Minikube doesn't have an official Terraform provider
# In production with AKS, this would be azurerm_kubernetes_cluster

resource "null_resource" "minikube_cluster" {
  triggers = {
    cluster_name = var.cluster_name
    environment  = var.environment
    cpus         = var.cpus
    memory       = var.memory
  }

  # Check if minikube is installed
  provisioner "local-exec" {
    command = "which minikube || (echo 'Minikube is not installed' && exit 1)"
  }

  # Delete existing cluster if it exists
  provisioner "local-exec" {
    command    = "minikube delete -p ${var.cluster_name}-${var.environment} 2>/dev/null || true"
    on_failure = continue
  }

  # Start Minikube cluster
  provisioner "local-exec" {
    command = <<-EOT
      minikube start \
        --profile=${var.cluster_name}-${var.environment} \
        --kubernetes-version=v${var.kubernetes_version} \
        --cpus=${var.cpus} \
        --memory=${var.memory} \
        --disk-size=${var.disk_size} \
        --driver=${var.driver} \
        --embed-certs
    EOT
  }

  # Enable addons
  provisioner "local-exec" {
    command = <<-EOT
      for addon in ${join(" ", var.addons)}; do
        minikube addons enable $addon -p ${var.cluster_name}-${var.environment}
      done
    EOT
  }

  # Wait for cluster to be ready
  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Ready nodes --all --timeout=300s"
  }

  # Cleanup on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "minikube delete -p ${self.triggers.cluster_name}-${self.triggers.environment}"
  }
}

# Create namespace for the application
resource "null_resource" "create_namespace" {
  depends_on = [null_resource.minikube_cluster]

  triggers = {
    namespace = var.namespace
  }

  provisioner "local-exec" {
    command = "kubectl create namespace ${var.namespace} --dry-run=client -o yaml | kubectl apply -f -"
  }

  # Set PSA (Pod Security Admission) to baseline
  provisioner "local-exec" {
    command = <<-EOT
      kubectl label namespace ${var.namespace} \
        pod-security.kubernetes.io/enforce=baseline \
        pod-security.kubernetes.io/audit=baseline \
        pod-security.kubernetes.io/warn=baseline \
        --overwrite
    EOT
  }
}

# Configure /etc/hosts for ingress (local development)
resource "null_resource" "configure_hosts" {
  depends_on = [null_resource.minikube_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      MINIKUBE_IP=$(minikube ip -p ${var.cluster_name}-${var.environment})
      
      # Remove old entries
      sudo sed -i '/vote.local/d' /etc/hosts 2>/dev/null || true
      sudo sed -i '/result.local/d' /etc/hosts 2>/dev/null || true
      
      # Add new entries
      echo "$MINIKUBE_IP vote.local" | sudo tee -a /etc/hosts
      echo "$MINIKUBE_IP result.local" | sudo tee -a /etc/hosts
    EOT
  }
}

# Output the kubeconfig for use with kubectl
resource "local_file" "kubeconfig" {
  depends_on = [null_resource.minikube_cluster]

  content  = "" # Placeholder - actual kubeconfig is managed by minikube
  filename = "${path.module}/kubeconfig-${var.environment}"

  provisioner "local-exec" {
    command = "kubectl config view --raw > ${path.module}/kubeconfig-${var.environment}"
  }
}
