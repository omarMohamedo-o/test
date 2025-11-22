resource "kubernetes_namespace" "voting_app" {
  metadata {
    name = var.namespace
    labels = {
      "app"                                = "voting-app"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
    }
  }
}
