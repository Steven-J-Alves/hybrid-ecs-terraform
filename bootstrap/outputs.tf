output "tfstate_bucket_name" {
  description = "Name of the SHARED S3 bucket used for Terraform remote state (data source, not created here)"
  value       = data.aws_s3_bucket.tfstate.bucket
}

output "lock_tables" {
  description = "Map of hybrid DynamoDB lock tables (stack name → table name)"
  value       = { for k, t in aws_dynamodb_table.lock : k => t.name }
}

output "ci_user_name" {
  description = "IAM user for CI apply"
  value       = aws_iam_user.ci.name
}

output "ci_access_key_id" {
  description = "Access key ID for kk-hybrid-terraform-ci"
  value       = aws_iam_access_key.ci.id
}

output "ci_secret_access_key" {
  description = "Secret access key for kk-hybrid-terraform-ci — DO NOT commit"
  value       = aws_iam_access_key.ci.secret
  sensitive   = true
}
