variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either dev or prod."
  }
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "voting-app"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28.3"
}

variable "cpus" {
  description = "Number of CPUs for the cluster"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory allocation for the cluster (MB)"
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "Disk size for the cluster (MB)"
  type        = string
  default     = "20g"
}

variable "driver" {
  description = "Driver to use for Minikube (docker, virtualbox, etc.)"
  type        = string
  default     = "docker"
}

variable "addons" {
  description = "List of Minikube addons to enable"
  type        = list(string)
  default     = ["ingress", "metrics-server", "dashboard"]
}

variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "voting-app"
}

# Environment-specific configurations
variable "app_replicas" {
  description = "Number of replicas for application pods"
  type        = map(number)
  default = {
    dev  = 1
    prod = 2
  }
}

variable "db_storage_size" {
  description = "Storage size for database (GB)"
  type        = map(string)
  default = {
    dev  = "5Gi"
    prod = "20Gi"
  }
}

variable "resource_limits" {
  description = "Resource limits per environment"
  type = map(object({
    cpu    = string
    memory = string
  }))
  default = {
    dev = {
      cpu    = "500m"
      memory = "512Mi"
    }
    prod = {
      cpu    = "1000m"
      memory = "1Gi"
    }
  }
}
