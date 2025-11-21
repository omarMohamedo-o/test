# Development Environment
environment        = "dev"
cluster_name       = "voting-app"
kubernetes_version = "1.28.3"

# Resource allocation for dev
cpus      = 2
memory    = 4096
disk_size = "20g"

# Addons
addons = ["ingress", "metrics-server"]

# Namespace
namespace = "voting-app"
