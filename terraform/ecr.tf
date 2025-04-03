resource "aws_ecr_repository" "juice_shop" {
  name = "juice-shop-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "juice-shop-repo"
    Environment = "sandbox"
    ManagedBy   = "Terraform"
  }
}

output "ecr_repository_url" {
  description = "URI of the ECR repository"
  value       = aws_ecr_repository.juice_shop.repository_url
}
