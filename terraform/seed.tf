# Separate seed job deployment
# Run ONLY when explicitly targeted:
#   terraform apply -target=null_resource.run_seed -auto-approve
#
# This resource is excluded from normal terraform apply by using count = 0
# It only runs when you explicitly target it

variable "run_seed" {
  description = "Set to true to run seed job (default: false for manual control)"
  type        = bool
  default     = false
}

resource "null_resource" "run_seed" {
  # Only create this resource when explicitly targeted
  # This prevents automatic execution during terraform apply
  count = var.run_seed ? 1 : 0

  triggers = {
    # Manual trigger - change to re-run
    seed_run_id = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "🌱 Starting seed job..."
      
      # Delete old seed pod if exists
      kubectl delete pod seed -n voting-app --ignore-not-found=true
      
      # Deploy seed job
      kubectl apply -f ../k8s/manifests/10-seed.yaml
      
      # Wait for seed pod to start
      echo "Waiting for seed pod to start..."
      sleep 3
      
      # Follow logs in background
      kubectl logs -f seed -n voting-app &
      LOG_PID=$!
      
      # Wait for completion
      echo "Waiting for seed job to complete (this may take 5-10 minutes)..."
      kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/seed -n voting-app --timeout=600s || \
      kubectl wait --for=jsonpath='{.status.phase}'=Failed pod/seed -n voting-app --timeout=5s || true
      
      # Kill log following
      kill $LOG_PID 2>/dev/null || true
      
      # Show final status
      echo " "
      echo "Seed job status:"
      kubectl get pod seed -n voting-app
      
      # Show vote counts (from seed logs)
      echo " "
      echo "Checking final vote counts from logs..."
      kubectl logs seed -n voting-app --tail=5
    EOT
  }

  depends_on = [
    null_resource.deploy_application
  ]
}

# Output instructions for running seed job
output "seed_instructions" {
  value = <<-EOT
    
    📝 SEED JOB INSTRUCTIONS:
    
    The seed job is OPTIONAL and will NOT run automatically.
    
    To run the seed job and generate 3000 test votes:
    
      terraform apply -var="run_seed=true" -target=null_resource.run_seed -auto-approve
    
    Or manually via kubectl:
    
      kubectl apply -f ../k8s/manifests/10-seed.yaml
      kubectl logs -f seed -n voting-app
    
  EOT
}
