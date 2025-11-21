# Production Environment
environment        = "prod"
cluster_name       = "voting-app"
kubernetes_version = "1.28.3"

# Increased resources for production
cpus      = 4
memory    = 8192
disk_size = "50g"

# All addons for production
addons = ["ingress", "metrics-server", "dashboard"]

# Namespace
namespace = "voting-app"
