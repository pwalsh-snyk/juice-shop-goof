resource "aws_iam_role_policy_attachment" "nodegroup_ecr_readonly" {
  role       = module.eks.eks_managed_node_groups["juice-shop-br"].iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
