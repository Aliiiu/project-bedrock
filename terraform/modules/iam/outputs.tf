output "cluster_role_arn" {
  description = "EKS cluster service role ARN"
  value       = aws_iam_role.cluster.arn
}

output "node_group_role_arn" {
  description = "EKS node group role ARN"
  value       = aws_iam_role.node_group.arn
}


output "developer_access_key_id" {
  description = "Access key ID for developer user"
  value       = aws_iam_access_key.developer.id
  sensitive   = true
}

output "developer_secret_access_key" {
  description = "Secret access key for developer user"
  value       = aws_iam_access_key.developer.secret
  sensitive   = true
}

output "developer_user_arn" {
  description = "ARN of the developer user"
  value       = aws_iam_user.developer.arn
}