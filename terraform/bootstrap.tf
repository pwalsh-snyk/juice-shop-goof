resource "null_resource" "wait_for_eks_ready" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<EOT
      echo "🕒 Waiting for EKS cluster to become ACTIVE..."
      for i in {1..30}; do
        STATUS=$(aws eks describe-cluster --region ${var.region} \
          --name ${module.eks.cluster_name} \
          --query "cluster.status" --output text)
        if [ "$STATUS" = "ACTIVE" ]; then
          echo "✅ EKS is ACTIVE!"
          exit 0
        fi
        echo "Still waiting... ($i)"
        sleep 10
      done
      echo "❌ EKS cluster not ready in time."
      exit 1
    EOT
  }
}
