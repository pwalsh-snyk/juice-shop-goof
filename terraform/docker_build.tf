resource "null_resource" "docker_build_push" {
  provisioner "local-exec" {
    command = <<EOT
      echo "🔐 Logging into ECR..."
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.juice_shop.repository_url}

      echo "🐳 Building Docker image..."
      docker build -t ${aws_ecr_repository.juice_shop.repository_url}:${var.image_tag} .

      echo "🚀 Pushing Docker image to ECR..."
      docker push ${aws_ecr_repository.juice_shop.repository_url}:${var.image_tag}
    EOT
  }

  triggers = {
    image_tag = var.image_tag
    timestamp = timestamp()
  }

  depends_on = [
    aws_ecr_repository.juice_shop,
    module.eks
  ]
}
