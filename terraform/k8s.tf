resource "kubernetes_manifest" "juice_shop_deploy" {
  provider   = kubernetes.eks
  depends_on = [module.eks]

  manifest = yamldecode(templatefile("${path.module}/k8s-src/juice-shop-deploy.yaml.tpl", {
    image = "${aws_ecr_repository.juice_shop.repository_url}:${var.image_tag}"
  }))
}

resource "kubernetes_manifest" "juice_shop_service" {
  provider   = kubernetes.eks
  depends_on = [module.eks]

  manifest = yamldecode(file("${path.module}/k8s-src/juice-shop-service.yaml"))
}

resource "kubernetes_manifest" "juice_shop_ingress" {
  provider   = kubernetes.eks
  depends_on = [module.eks]

  manifest = yamldecode(file("${path.module}/k8s-src/juice-shop-ingress.yaml"))
}
